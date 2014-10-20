# encoding: utf-8

class PhenotypeAttempt::DistributionCentre < ApplicationModel
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

  access_association_by_attribute :deposited_material, :name
  access_association_by_attribute :centre, :name

  before_save do
    ## TODO: Update martbuilder so we don't need to continue updating the boolean.
    self[:is_distributed_by_emma] = self.distribution_network == 'EMMA'

    if (!self.distribution_network.blank?) && self.centre.name == 'KOMP Repo'
      self.centre = self.phenotype_attempt.mi_plan.production_centre
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
    return 'phenotype attempt distribution centre'
  end

  def reconcile_with_repo( repository_name, reposcraper )
    # instantiate reposcraper if nil
    if ( reposcraper.nil? )
      reposcraper = RepositoryGeneDetailsScraper.new()
    end

    # get marker symbol from gene
    gene          = self.mouse_allele_mod.mi_plan.gene
    marker_symbol = gene.marker_symbol

    # use geneid or marker symbol to fetch gene details hash
    case repository_name
      when KOMP_CENTRE_NAME
        geneid            = gene.komp_repo_geneid
        gene_repo_details = reposcraper.fetch_komp_allele_details( marker_symbol, geneid )
      else
        puts "ERROR : repository name #{repository_name} not recognised for Mouse Allele Mod id #{self.mouse_allele_mod.id}, cannot reconcile"
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
        if ( matching_allele['is_live_mice'] == 1 )
          puts "repo has live mice"
        end

        if ( matching_allele['is_cryo_recovery'] == 1 )
          puts "repo has cryo recovery mice"
        end

        if ( matching_allele['is_germ_plasm'] == 1 )
          puts "repo has germ plasm"
        end

        if ( matching_allele['is_embryos'] == 1 )
          puts "repo has embryos"
        end
        # any match counts as reconciled
        if (( matching_allele['is_live_mice']     == 1 ) || ( matching_allele['is_cryo_recovery'] == 1 ) ||
          ( matching_allele['is_germ_plasm']    == 1 ) || ( matching_allele['is_embryos']       == 1 ))
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
#
