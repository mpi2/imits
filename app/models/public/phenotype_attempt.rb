# encoding: utf-8

class Public::PhenotypeAttempt < ::PhenotypeAttempt

  extend ::AccessAssociationByAttribute
  include ::Public::Serializable
  include ::Public::DistributionCentresAttributes
  include ::ApplicationModel::BelongsToMiPlan::Public

  FULL_ACCESS_ATTRIBUTES = %w{
    colony_name
    consortium_name
    production_centre_name
    is_active
    rederivation_started
    rederivation_complete
    number_of_cre_matings_successful
    phenotyping_started
    phenotyping_complete
    mouse_allele_type
    deleter_strain_name
    distribution_centres_attributes
    phenotyping_productions_attributes
    colony_background_strain_name
    cre_excision_required
    tat_cre
    mi_plan_id
    status_stamps_attributes
    report_to_public
    phenotyping_experiments_started
    qc_southern_blot_result
    qc_five_prime_lr_pcr_result
    qc_five_prime_cassette_integrity_result
    qc_tv_backbone_assay_result
    qc_neo_count_qpcr_result
    qc_lacz_count_qpcr_result
    qc_neo_sr_pcr_result
    qc_loa_qpcr_result
    qc_homozygous_loa_sr_pcr_result
    qc_lacz_sr_pcr_result
    qc_mutant_specific_sr_pcr_result
    qc_loxp_confirmation_result
    qc_three_prime_lr_pcr_result
    qc_critical_region_qpcr_result
    qc_loxp_srpcr_result
    qc_loxp_srpcr_and_sequencing_result
    ready_for_website
  }

  READABLE_ATTRIBUTES = %w{
    id
    distribution_centres_formatted_display
    status_name
    status_dates
    marker_symbol
    mouse_allele_symbol_superscript
    mouse_allele_symbol
    allele_symbol
    mi_attempt_colony_name
    mi_attempt_colony_background_strain_name
    mi_attempt_colony_background_mgi_strain_accession_id
    mi_attempt_colony_background_mgi_strain_name
    colony_background_strain_mgi_accession
    colony_background_strain_mgi_name
    mgi_accession_id
  } + FULL_ACCESS_ATTRIBUTES

  WRITABLE_ATTRIBUTES = %w{
  } + FULL_ACCESS_ATTRIBUTES

  attr_accessible(*WRITABLE_ATTRIBUTES)

  accepts_nested_attributes_for :distribution_centres, :allow_destroy => true
  accepts_nested_attributes_for :phenotyping_productions, :allow_destroy => true

  access_association_by_attribute :mi_attempt, :colony_name
  access_association_by_attribute :deleter_strain, :name

  validates :mi_attempt_colony_name, :presence => true

  validate do |me|
    if me.changed.include?('mi_attempt_id') and ! me.new_record?
      me.errors.add :mi_attempt_colony_name, 'cannot be changed'
    end
  end

  validate do |me|
    if me.changes.has_key?('colony_name') and (! me.changes[:colony_name][0].nil?) and me.status.order_by >= PhenotypeAttempt::Status.find_by_code('pds').order_by #Phenotype Started
      me.errors.add(:phenotype_attempt, "colony_name can not be changed once phenotyping has started")
    end
  end

  # BEGIN Callbacks

  # END Callbacks


  def status_name; status.name; end

  def status_dates
    retval = reportable_statuses_with_latest_dates
    retval.each do |status_name, date|
      retval[status_name] = date.to_s
    end
    return retval
  end

 def phenotyping_productions_attributes
   return phenotyping_productions.map(&:as_json)
 end

  def self.translations
    return {
      'marker_symbol' => 'mi_plan_gene_marker_symbol',
      'consortium' => 'mi_plan_consortium',
      'production_centre' => 'mi_plan_production_centre'
    }
  end
end

# == Schema Information
#
# Table name: phenotype_attempts
#
#  id                                  :integer         not null, primary key
#  mi_attempt_id                       :integer         not null
#  status_id                           :integer         not null
#  is_active                           :boolean         default(TRUE), not null
#  rederivation_started                :boolean         default(FALSE), not null
#  rederivation_complete               :boolean         default(FALSE), not null
#  number_of_cre_matings_started       :integer         default(0), not null
#  number_of_cre_matings_successful    :integer         default(0), not null
#  phenotyping_started                 :boolean         default(FALSE), not null
#  phenotyping_complete                :boolean         default(FALSE), not null
#  created_at                          :datetime
#  updated_at                          :datetime
#  mi_plan_id                          :integer         not null
#  colony_name                         :string(125)     not null
#  mouse_allele_type                   :string(3)
#  deleter_strain_id                   :integer
#  colony_background_strain_id         :integer
#  cre_excision_required               :boolean         default(TRUE), not null
#  tat_cre                             :boolean         default(FALSE)
#  report_to_public                    :boolean         default(TRUE), not null
#  phenotyping_experiments_started     :date
#  qc_southern_blot_id                 :integer
#  qc_five_prime_lr_pcr_id             :integer
#  qc_five_prime_cassette_integrity_id :integer
#  qc_tv_backbone_assay_id             :integer
#  qc_neo_count_qpcr_id                :integer
#  qc_neo_sr_pcr_id                    :integer
#  qc_loa_qpcr_id                      :integer
#  qc_homozygous_loa_sr_pcr_id         :integer
#  qc_lacz_sr_pcr_id                   :integer
#  qc_mutant_specific_sr_pcr_id        :integer
#  qc_loxp_confirmation_id             :integer
#  qc_three_prime_lr_pcr_id            :integer
#  qc_lacz_count_qpcr_id               :integer
#  qc_critical_region_qpcr_id          :integer
#  qc_loxp_srpcr_id                    :integer
#  qc_loxp_srpcr_and_sequencing_id     :integer
#
# Indexes
#
#  index_phenotype_attempts_on_colony_name  (colony_name) UNIQUE
#


# == Schema Information
#
# Table name: phenotype_attempts
#
#  id                                  :integer         not null, primary key
#  mi_attempt_id                       :integer         not null
#  status_id                           :integer         not null
#  is_active                           :boolean         default(TRUE), not null
#  rederivation_started                :boolean         default(FALSE), not null
#  rederivation_complete               :boolean         default(FALSE), not null
#  number_of_cre_matings_started       :integer         default(0), not null
#  number_of_cre_matings_successful    :integer         default(0), not null
#  phenotyping_started                 :boolean         default(FALSE), not null
#  phenotyping_complete                :boolean         default(FALSE), not null
#  created_at                          :datetime
#  updated_at                          :datetime
#  mi_plan_id                          :integer         not null
#  colony_name                         :string(125)     not null
#  mouse_allele_type                   :string(3)
#  deleter_strain_id                   :integer
#  colony_background_strain_id         :integer
#  cre_excision_required               :boolean         default(TRUE), not null
#  tat_cre                             :boolean         default(FALSE)
#  report_to_public                    :boolean         default(TRUE), not null
#  phenotyping_experiments_started     :date
#  qc_southern_blot_id                 :integer
#  qc_five_prime_lr_pcr_id             :integer
#  qc_five_prime_cassette_integrity_id :integer
#  qc_tv_backbone_assay_id             :integer
#  qc_neo_count_qpcr_id                :integer
#  qc_neo_sr_pcr_id                    :integer
#  qc_loa_qpcr_id                      :integer
#  qc_homozygous_loa_sr_pcr_id         :integer
#  qc_lacz_sr_pcr_id                   :integer
#  qc_mutant_specific_sr_pcr_id        :integer
#  qc_loxp_confirmation_id             :integer
#  qc_three_prime_lr_pcr_id            :integer
#  qc_lacz_count_qpcr_id               :integer
#  qc_critical_region_qpcr_id          :integer
#  qc_loxp_srpcr_id                    :integer
#  qc_loxp_srpcr_and_sequencing_id     :integer
#  ready_for_website                   :date
#
# Indexes
#
#  index_phenotype_attempts_on_colony_name  (colony_name) UNIQUE
#

