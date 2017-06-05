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

  def calculate_order_link( config = nil )

    params = {
      :distribution_centre_name       => centre_name,
      :deposited_material             => deposited_material,
      :dc_start_date                  => start_date,
      :dc_end_date                    => end_date
    }

    # call class method
    return self.calculate_order_link( self.centre_name, params )
  end


  def self.calculate_order_link( config_name, params)

    raise "Expecting to find config key name to compile order link" if config_name.nil?
    raise "Expecting to be supplied with what type of tissue was deposited" if params[:deposited_material].blank?

    order_from_name ||= []
    order_from_url  ||= []

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

    details = ''
    order_from_name = config_name

    centre = Centre.where("contact_email IS NOT NULL AND name = '#{config_name}'").first
    if centre
      details = centre
      order_from_url = "mailto:#{details.contact_email}?subject=#{params[:deposited_material]} enquiry"
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
