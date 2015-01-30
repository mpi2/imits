# encoding: utf-8

class PhenotypeAttempt::DistributionCentre < ApplicationModel
  extend AccessAssociationByAttribute
  include Public::Serializable
  include ApplicationModel::DistributionCentre

  class Error <  ApplicationModel::ValidationError; end
  class UnsuitableDistributionNetworkError < Error; end
  class UnsuitableDistributionCentreError < Error; end

  acts_as_audited

  WRITABLE_ATTRIBUTES = %w{
  } + FULL_ACCESS_ATTRIBUTES + ['phenotype_attempt_id']

  KOMP_CENTRE_NAME = 'KOMP Repo'

  attr_accessible(*WRITABLE_ATTRIBUTES)

  belongs_to :phenotype_attempt
  belongs_to :mouse_allele_mod
  belongs_to :centre
  belongs_to :deposited_material

  validates :phenotype_attempt_id, :presence => true
  validates :centre_id, :presence => true
  validates :deposited_material_id, :presence => true

  validate do |dc|
    validate_distribution_centre_entry( dc )
  end

  access_association_by_attribute :deposited_material, :name
  access_association_by_attribute :centre, :name

  before_save do
    ## TODO: Update martbuilder so we don't need to continue updating the boolean.
    self[:is_distributed_by_emma] = self.distribution_network == 'EMMA'

    # TODO: excluded for simplicity Nov 2014
    # self.update_whether_distribution_centre_available # this method in module mi_attempt_distribution_centre

    true # Rails doesn't save if you return false.
  end

  def self.readable_name
    return 'phenotype attempt distribution centre'
  end

  def reconcile_with_repo( repository_name, reposcraper )

    gene_repo_details = nil

    # use geneid or marker symbol to fetch gene details hash
    case repository_name
    when EMMA_REPO_NAME
      gene_repo_details = reconcile_with_emma_repo( reposcraper )
    when KOMP_CENTRE_NAME
      gene_repo_details = reconcile_with_komp_repo( reposcraper )
    when MMRRC_REPO_NAME
      gene_repo_details = reconcile_with_mmrrc_repo( reposcraper )
    else
      puts "ERROR : repository name #{repository_name} not recognised for Mi Attempt id #{self.mi_attempt.id}, cannot reconcile"
      return
    end

    production_centre = self.mouse_allele_mod.mi_plan.production_centre.name
    puts "Production centre = #{production_centre}"

    # possible results here:
    # nil -> means no geneid was found at all
    # hash containing geneid and empty alleles hash -> means gene checked but no products
    # hash containing geneid and alleles hash containing 1 or more alleles -> has products but need to check flags
    if ( gene_repo_details.nil? )
      puts "WARN : No gene details found for this gene on repository, reconciled set to not found"
      self.reconciled = 'not found'
    elsif ( gene_repo_details['alleles'].count == 0 )
      puts "WARN : No product details found for this gene in repository, reconciled set to false"
      self.reconciled = 'false'
    else
      mouse_allele_mod_allele_symbol = self.mouse_allele_mod.allele_symbol

      if ( mouse_allele_mod_allele_symbol.nil? )
        puts "WARN : No allele name found for Mouse Allele Mod id #{self.mouse_allele_mod.id}, cannot reconcile"
        return
      end

      if mouse_allele_mod_allele_symbol.include? '<sup>'
        mouse_allele_mod_allele_symbol_unsplit = mouse_allele_mod_allele_symbol

        # strip out the superscript part of the allele symbol
        split_array = mouse_allele_mod_allele_symbol_unsplit.match(/\w*<sup>(\S*)<\/sup>/)

        if ( split_array.nil? || split_array.length < 1 )
          puts "WARN : Allele name #{mouse_allele_mod_allele_symbol_unsplit} format split length not correct for Mouse Allele Mod id #{self.mouse_allele_mod.id}, cannot reconcile"
          return
        end

        mouse_allele_mod_allele_symbol = split_array[1]

        if ( mouse_allele_mod_allele_symbol.nil? )
          puts "WARN : Allele name #{mouse_allele_mod_allele_symbol} format not understood for Mouse Allele Mod id #{self.mouse_allele_mod.id}, cannot reconcile"
          return
        end
      end

      puts "Sanger Mouse Allele Mod allele : #{mouse_allele_mod_allele_symbol}"

      if gene_repo_details['alleles'].has_key?(mouse_allele_mod_allele_symbol)

        matching_allele = gene_repo_details['alleles'][mouse_allele_mod_allele_symbol]

        if ( matching_allele['is_mice'] == 1 )
          puts "repo has mice"
        end

        if ( matching_allele['is_recovery'] == 1 )
          puts "repo has recovery mice"
        end

        if ( matching_allele['is_germ_plasm'] == 1 )
          puts "repo has germ plasm"
        end

        if ( matching_allele['is_embryos'] == 1 )
          puts "repo has embryos"
        end
        # any match counts as reconciled
        if (( matching_allele['is_mice'] == 1 ) || ( matching_allele['is_recovery'] == 1 ) ||
            ( matching_allele['is_germ_plasm'] == 1 ) || ( matching_allele['is_embryos'] == 1 ))
          self.reconciled = 'true'
        else
          self.reconciled = 'false'
        end # check for allele flags
      else
        puts "WARN : No repository allele found to match to Mouse Allele Mod allele #{mouse_allele_mod_allele_symbol}, reconciled set to false"
        self.reconciled = 'false'
      end # check for allele details
    end # check for gene details

    begin
      self.reconciled_at = Time.now # UTC time
      self.save
      puts "Allele reconciled to #{self.reconciled} at time #{self.reconciled_at}"
    rescue => e
      "ERROR : Failed to save phenotype attempt distribution centre for Mouse Allele Mod id #{self.mouse_allele_mod.id}, cannot reconcile"
    end

  end

  def reconcile_with_emma_repo( reposcraper )
    # instantiate reposcraper if nil
    if ( reposcraper.nil? )
      reposcraper = ScraperEmmaRepository.new()
    end

    marker_symbol     = self.mi_attempt.mi_plan.gene.marker_symbol
    gene_repo_details = reposcraper.fetch_emma_allele_details( marker_symbol )

    return gene_repo_details
  end

  def reconcile_with_komp_repo( reposcraper )
    # instantiate reposcraper if nil
    if ( reposcraper.nil? )
      reposcraper = ScraperKompRepository.new()
    end

    gene              = self.mouse_allele_mod.mi_plan.gene
    marker_symbol     = gene.marker_symbol
    geneid            = gene.komp_repo_geneid

    gene_repo_details = reposcraper.fetch_komp_allele_details( marker_symbol, geneid )

    return gene_repo_details
  end

  def reconcile_with_mmrrc_repo( reposcraper )
    # instantiate reposcraper if nil
    if ( reposcraper.nil? )
      reposcraper = ScraperMmrrcRepository.new()
    end

    marker_symbol     = self.mi_attempt.mi_plan.gene.marker_symbol
    gene_repo_details = reposcraper.fetch_mmrrc_allele_details( marker_symbol )

    return gene_repo_details
  end

  def calculate_order_link( config = nil )

    params = {
      :distribution_network_name      => self[:distribution_network],
      :distribution_centre_name       => self.centre_name,
      :production_centre_name         => self.try(:mouse_allele_mod).try(:mi_plan).try(:production_centre).try(:name),
      :reconciled                     => self[:reconciled],
      :available                      => self[:available],
      :dc_start_date                  => self[:start_date],
      :dc_end_date                    => self[:end_date],
      :ikmc_project_id                => self.try(:mouse_allele_mod).try(:mi_attempt).try(:es_cell).try(:ikmc_project_id),
      :marker_symbol                  => self.try(:mouse_allele_mod).try(:mi_plan).try(:gene).try(:marker_symbol)
    }

    # call class method
    return ApplicationModel::DistributionCentre.calculate_order_link( params, config )
  end

end

# == Schema Information
#
# Table name: phenotype_attempt_distribution_centres
#
#  id                     :integer          not null, primary key
#  start_date             :date
#  end_date               :date
#  phenotype_attempt_id   :integer          not null
#  deposited_material_id  :integer          not null
#  centre_id              :integer          not null
#  is_distributed_by_emma :boolean          default(FALSE), not null
#  created_at             :datetime
#  updated_at             :datetime
#  distribution_network   :string(255)
#  mouse_allele_mod_id    :integer
#  reconciled             :string(255)      default("not checked"), not null
#  reconciled_at          :datetime
#  available              :boolean          default(TRUE), not null
#
