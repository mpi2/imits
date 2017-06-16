# encoding: utf-8

class PhenotypingProduction::TissueDistributionCentre < ActiveRecord::Base
  extend AccessAssociationByAttribute
  include Public::Serializable

    FULL_ACCESS_ATTRIBUTES = %w{
    start_date
    end_date
    deposited_material
    centre_name
    _destroy
  }

  READABLE_ATTRIBUTES = %w{
    id
  } + FULL_ACCESS_ATTRIBUTES

  DEPOSITED_TISSUE_MATERIAL = %w{
    Fixed\ Tissue
    Paraffin-embedded\ Tissue\ Sections
  }

  belongs_to :phenotyping_production
  belongs_to :centre

  access_association_by_attribute :centre, :name

  before_validation do |tdc|
    if tdc.centre.blank? && !tdc.phenotyping_production.phenotyping_centre_name.blank?
      tdc.centre_name = tdc.phenotyping_production.phenotyping_centre_name
    end
    return true
  end

  validates :phenotyping_production, :presence => true
  validates :centre, :presence => true
  validates :deposited_material, :presence => true
  validates :deposited_material, uniqueness: { scope: :phenotyping_production_id, message: "is already been distributed" }

  def calculate_order_link
    params = {}
    params[:distribution_centre_name] = centre_name
    params[:deposited_material] = deposited_material
    params[:dc_start_date] = start_date
    params[:dc_end_date] = end_date

    self.class.calculate_order_link( params )
  end

  def self.calculate_order_link( params, config = nil )

    distribution_centre_name  = params[:distribution_centre_name]
    config ||= YAML.load_file("#{Rails.root}/config/tissue_dist_centre_urls.yml")

    return self.compile_order_link( distribution_centre_name, params, config )
  end

  ##
  # Compiles an order link given a config name (network, distribution or production centre name), parameters
  # and a configuration
  ##
  def self.compile_order_link( config_name, params, config )

    raise "Expecting to find config key name to compile order link" if config_name.nil?

    raise "Distribution centre config cannot be nil"  if config.nil?

    raise "Missing deposited_material parameter" unless params.has_key?(:deposited_material)

    order_from_name = ""
    order_from_url  = ""

    current_time = Time.now

    if params[:dc_start_date]
      start_date = params[:dc_start_date]
    else
      start_date = current_time
    end

    if params[:dc_end_date]
      end_date = params[:dc_end_date]
    else
      end_date = current_time
    end

    range = start_date.to_time..end_date.to_time

    if ( ! range.cover?(current_time) )
      return []
    end

    deposited_material = params[:deposited_material]
    details = ''
    order_from_name = deposited_material

    if ( config.has_key?(config_name) && ( ( !config[config_name][:default].blank? ) || ( !config[config_name][:preferred].blank? ) ) )
      details = config[config_name]

      if ( !config[config_name][:default].blank? )
        order_from_url  = details[:default]
      end # default

      if ( !config[config_name][:preferred].blank? )
        project_id    = params[:ikmc_project_id]
        marker_symbol = params[:marker_symbol]

        if ( project_id && ( details[:preferred] =~ /PROJECT_ID/ ) )
          order_from_url = details[:preferred].gsub( /PROJECT_ID/, project_id )
        elsif ( marker_symbol && ( details[:preferred] =~ /MARKER_SYMBOL/ ) )
          order_from_url = details[:preferred].gsub( /MARKER_SYMBOL/, marker_symbol )
        end
      end # preferred

    elsif !Centre.where("contact_email IS NOT NULL AND name = '#{config_name}'").blank?
      # no useful entry in config, attempt to use centre contact
      centre = Centre.where("contact_email IS NOT NULL AND name = '#{config_name}'").first
      if centre
        details = centre
        order_from_url = "mailto:#{details.contact_email}?subject=#{deposited_material} enquiry"
      end
    end

    if ( order_from_name.blank? || order_from_url.blank? )
      return []
    else
      return [ order_from_name, order_from_url ]
    end
  end

end

# == Schema Information
#
# Table name: phenotyping_production_tissue_distribution_centres
#
#  id                        :integer          not null, primary key
#  start_date                :date
#  end_date                  :date
#  phenotyping_production_id :integer          not null
#  deposited_material        :string(255)      not null
#  centre_id                 :integer          not null
#  created_at                :datetime         not null
#  updated_at                :datetime         not null
#
