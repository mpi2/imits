# encoding: utf-8

class Colony::DistributionCentre < ApplicationModel
  extend AccessAssociationByAttribute
  include Public::Serializable
  include ApplicationModel::DistributionCentre

  class Error <  ApplicationModel::ValidationError; end
  class UnsuitableDistributionNetworkError < Error; end
  class UnsuitableDistributionCentreError < Error; end

  acts_as_audited

  WRITABLE_ATTRIBUTES = %w{
  } + FULL_ACCESS_ATTRIBUTES + ['colony_id']

  KOMP_CENTRE_NAME = 'KOMP Repo'

  attr_accessible(*WRITABLE_ATTRIBUTES)

  belongs_to :colony
  belongs_to :centre
  belongs_to :deposited_material

  validates :colony_id, :presence => true
  validates :centre_id, :presence => true
  validates :deposited_material_id, :presence => true

  validate do |dc|
    validate_distribution_centre_entry( dc )
  end

  access_association_by_attribute :deposited_material, :name
  access_association_by_attribute :centre, :name


  def self.readable_name
    return 'distribution centre'
  end

#   def reconcile_with_repo( repository_name, reposcraper )
#     # instantiate reposcraper if nil
#     if ( reposcraper.nil? )
#       reposcraper = RepositoryGeneDetailsScraper.new()
#     end
#
#     # get marker symbol from gene
#     gene          = self.mi_attempt.mi_plan.gene
#     marker_symbol = gene.marker_symbol
#
#     # use geneid or marker symbol to fetch gene details hash
#     case repository_name
#       when KOMP_CENTRE_NAME
#         geneid            = gene.komp_repo_geneid
#         gene_repo_details = reposcraper.fetch_komp_allele_details( marker_symbol, geneid )
#       else
#         puts "ERROR : repository name #{repository_name} not recognised for Mi Attempt id #{self.mi_attempt.id}, cannot reconcile"
#         return
#     end
#
#     production_centre = self.mi_attempt.mi_plan.production_centre.name
#     puts "Production centre = #{production_centre}"
#
#     # possible results here:
#     # nil -> means no geneid was found at all
#     # hash containing geneid and empty alleles hash -> means gene checked but no products
#     # hash containing geneid and alleles hash containing 1 or more alleles -> has products but need to check flags
#     if ( gene_repo_details.nil? )
#       puts "WARN : No gene details found for this gene on repository, reconciled set to not found"
#       self.reconciled = 'not found'
#     elsif ( gene_repo_details['alleles'].count == 0 )
#       puts "WARN : No product details found for this gene in repository, reconciled set to false"
#       self.reconciled = 'false'
#     else
#       mi_attempt_allele_symbol_unsplit = self.mi_attempt.allele_symbol
#
#       if ( mi_attempt_allele_symbol_unsplit.nil? )
#         puts "WARN : Allele name #{mi_attempt_allele_symbol_unsplit} format not understood for Mi Attempt id #{self.mi_attempt.id}, cannot reconcile"
#         return
#       end
#
#       # strip out the superscript part of the allele symbol
#       split_array = mi_attempt_allele_symbol_unsplit.match(/\w*<sup>(\S*)<\/sup>/)
#
#       if ( split_array.nil? || split_array.length < 1 )
#         puts "WARN : Allele name #{mi_attempt_allele_symbol_unsplit} format split length not correct for Mi Attempt id #{self.mi_attempt.id}, cannot reconcile"
#         return
#       end
#
#       mi_attempt_allele_symbol = split_array[1]
#
#       if ( mi_attempt_allele_symbol.nil? )
#         puts "WARN : No allele name found for Mi Attempt id #{self.mi_attempt.id}, cannot reconcile"
#         return
#       end
#
#       puts "Sanger Mi Attempt allele : #{mi_attempt_allele_symbol}"
#
#       if gene_repo_details['alleles'].has_key?(mi_attempt_allele_symbol)
#
#         matching_allele = gene_repo_details['alleles'][mi_attempt_allele_symbol]
#
#         if ( matching_allele['is_mice'] == 1 )
#           puts "repo has mice"
#         end
#
#         if ( matching_allele['is_recovery'] == 1 )
#           puts "repo has recovery mice"
#         end
#
#         if ( matching_allele['is_germ_plasm'] == 1 )
#           puts "repo has germ plasm"
#         end
#
#         if ( matching_allele['is_embryos'] == 1 )
#           puts "repo has embryos"
#         end
#         # any match counts as reconciled
#         if (( matching_allele['is_mice'] == 1 ) || ( matching_allele['is_recovery'] == 1 ) ||
#             ( matching_allele['is_germ_plasm'] == 1 ) || ( matching_allele['is_embryos'] == 1 ))
#           self.reconciled = 'true'
#         else
#           self.reconciled = 'false'
#         end # check for allele flags
#       else
#         puts "WARN : No repository allele found to match to Mi Attempt allele #{mi_attempt_allele_symbol}, reconciled set to false"
#         self.reconciled = 'false'
#       end # check for allele details
#     end # check for gene details
#
#     begin
#       self.reconciled_at = Time.now # UTC time
#       self.save
#       puts "Allele reconciled to #{self.reconciled} at time #{self.reconciled_at}"
#     rescue => e
#       "ERROR : Failed to save mi attempt distribution centre for Mi Attempt id #{self.mi_attempt.id}, cannot reconcile"
#     end
#
#   end

  def calculate_order_link( config = nil )

    params = {
      :distribution_network_name      => self[:distribution_network],
      :distribution_centre_name       => self.centre_name,
      :production_centre_name         => self.colony.try(:mi_plan).try(:production_centre_name),
      :reconciled                     => self[:reconciled],
      :available                      => self[:available],
      :dc_start_date                  => self[:start_date],
      :dc_end_date                    => self[:end_date],
      :ikmc_project_id                => self.colony.try(:mi_attempt).try(:es_cell).try(:ikmc_project_id),
      :marker_symbol                  => self.colony.try(:mi_plan).try(:gene).try(:marker_symbol)
    }

    # call class method
    return ApplicationModel::DistributionCentre.calculate_order_link( params, config )
  end

end

# == Schema Information
#
# Table name: colony_distribution_centres
#
#  id                    :integer          not null, primary key
#  colony_id             :integer          not null
#  deposited_material_id :integer          not null
#  distribution_network  :string(255)
#  centre_id             :integer          not null
#  start_date            :date
#  end_date              :date
#  reconciled            :string(255)      default("not checked"), not null
#  reconciled_at         :datetime
#  available             :boolean          default(TRUE), not null
#  created_at            :datetime         not null
#  updated_at            :datetime         not null
#
