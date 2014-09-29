# encoding: utf-8

class MiAttempt::DistributionCentre < ApplicationModel
  extend AccessAssociationByAttribute
  include Public::Serializable

  acts_as_audited

  DISTRIBUTION_NETWORKS = %w{
    CMMR
    EMMA
    MMRRC
  }

  FULL_ACCESS_ATTRIBUTES = %w{
    start_date
    end_date
    deposited_material_name
    centre_name
    is_distributed_by_emma
    distribution_network
    _destroy
  }

  READABLE_ATTRIBUTES = %w{
    id
  } + FULL_ACCESS_ATTRIBUTES

  WRITABLE_ATTRIBUTES = %w{
  } + FULL_ACCESS_ATTRIBUTES + ['mi_attempt_id']

  attr_accessible(*WRITABLE_ATTRIBUTES)

  belongs_to :mi_attempt
  belongs_to :centre
  belongs_to :deposited_material

  validates :mi_attempt_id, :presence => true
  validates :centre_id, :presence => true
  validates :deposited_material_id, :presence => true

  access_association_by_attribute :deposited_material, :name
  access_association_by_attribute :centre, :name

  before_save do
    ## TODO: Update martbuilder so we don't need to continue updating the boolean.
    self[:is_distributed_by_emma] = self.distribution_network == 'EMMA'

    if (!self.distribution_network.blank?) && self.centre.name == 'KOMP Repo'
      self.centre = self.mi_attempt.mi_plan.production_centre
    end

    true # Rails doesn't save if you return false.
  end

  ## This is for backwards compatibility with portal.
  def is_distributed_by_emma
    self.distribution_network == 'EMMA'
  end

  def is_distributed_by_emma=(bool)
    ## Set distribution_network to EMMA if `bool` is true
    if bool
      self.distribution_network = 'EMMA'
    ## Set distribution_network to nothing if `bool` is false and already set to EMMA, or leave as previous value.
    elsif is_distributed_by_emma
      self.distribution_network = nil
    end
  end

  def self.readable_name
    return 'mi attempt distribution centre'
  end

  def reconcile_with_repo( repository_name, reposcraper )
    # instantiate reposcraper if nil (TODO : and fetch gene list until geneid stored on gene table)
    if ( reposcraper.nil? )
      reposcraper = RepositoryGeneDetailsScraper.new()
      reposcraper.fetch_komp_catalog_gene_list()
    end

    # get marker symbol from gene
    gene = self.mi_attempt.mi_plan.gene
    marker_symbol = gene.marker_symbol

    # use marker symbol to fetch gene details hash
    gene_repo_details = reposcraper.fetch_komp_allele_details_by_marker_symbol( marker_symbol )

    # we now have a hash containing potentially 0-many alleles with flags, or nil if no details found
    unless ( gene_repo_details.nil? || gene_repo_details.count == 0 )
      # pp gene_repo_details

      mi_attempt_allele_symbol_unsplit = self.mi_attempt.allele_symbol

      if ( mi_attempt_allele_symbol_unsplit.nil? )
        puts "WARN : Allele name #{mi_attempt_allele_symbol_unsplit} format not understood for Mi Attempt id #{self.mi_attempt.id}, cannot reconcile"
        return
      end

      # strip out the superscript part of the allele symbol
      split_array = mi_attempt_allele_symbol_unsplit.match(/\w*<sup>(\S*)<\/sup>/)

      if ( split_array.nil? || split_array.length < 1 )
        puts "WARN : Allele name #{mi_attempt_allele_symbol_unsplit} format not understood for Mi Attempt id #{self.mi_attempt.id}, cannot reconcile"
        return
      end

      mi_attempt_allele_symbol = split_array[1]

      if ( mi_attempt_allele_symbol.nil? )
        puts "WARN : No allele name found for Mi Attempt id #{self.mi_attempt.id}, cannot reconcile"
        return
      end

      if gene_repo_details['alleles'].has_key?(mi_attempt_allele_symbol)
        if (( gene_repo_details['alleles'][mi_attempt_allele_symbol]['is_live_mice']     == 1 ) ||
          ( gene_repo_details['alleles'][mi_attempt_allele_symbol]['is_cryo_recovery'] == 1 ) ||
          ( gene_repo_details['alleles'][mi_attempt_allele_symbol]['is_germ_plasm']    == 1 ) ||
          ( gene_repo_details['alleles'][mi_attempt_allele_symbol]['is_embryos']       == 1 ))
          puts "Allele reconciled TRUE"
          self.reconciled = 'true'
        else
          puts "Allele reconciled FALSE"
          self.reconciled = 'false'
        end

        begin
          self.save
        rescue => e
          "ERROR : Failed to save mi attempt distribution centre for Mi Attempt id #{self.mi_attempt.id}, cannot reconcile"
        end
      else
        puts "WARN : No repository allele found to match to Mi Attempt allele #{mi_attempt_allele_symbol}, cannot reconcile"
      end
    end
  end

end

# == Schema Information
#
# Table name: mi_attempt_distribution_centres
#
#  id                     :integer          not null, primary key
#  start_date             :date
#  end_date               :date
#  mi_attempt_id          :integer          not null
#  deposited_material_id  :integer          not null
#  centre_id              :integer          not null
#  is_distributed_by_emma :boolean          default(FALSE), not null
#  created_at             :datetime
#  updated_at             :datetime
#  distribution_network   :string(255)
#  reconciled             :string(255)      default("not checked"), not null
#
