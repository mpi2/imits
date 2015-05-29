class Public::MiAttempt < ::MiAttempt

  include ::Public::Serializable
  include ::Public::MutagenesisFactorAttributes
  include ::Public::ColonyAttributes
  include ::ApplicationModel::BelongsToMiPlan::Public

  FULL_ACCESS_ATTRIBUTES = %w{
    es_cell_name
    mi_date
    colony_name
    consortium_name
    production_centre_name
    blast_strain_name
    total_blasts_injected
    total_transferred
    number_surrogates_receiving
    total_pups_born
    total_female_chimeras
    total_male_chimeras
    total_chimeras
    number_of_males_with_0_to_39_percent_chimerism
    number_of_males_with_40_to_79_percent_chimerism
    number_of_males_with_80_to_99_percent_chimerism
    number_of_males_with_100_percent_chimerism
    colony_background_strain_name
    test_cross_strain_name
    date_chimeras_mated
    number_of_chimera_matings_attempted
    number_of_chimera_matings_successful
    number_of_chimeras_with_glt_from_cct
    number_of_chimeras_with_glt_from_genotyping
    number_of_chimeras_with_0_to_9_percent_glt
    number_of_chimeras_with_10_to_49_percent_glt
    number_of_chimeras_with_50_to_99_percent_glt
    number_of_chimeras_with_100_percent_glt
    total_f1_mice_from_matings
    number_of_cct_offspring
    number_of_het_offspring
    number_of_live_glt_offspring
    mouse_allele_type
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
    report_to_public
    is_active
    is_released_from_genotyping
    comments
    genotyping_comment
    distribution_centres_attributes
    mi_plan_id
    status_stamps_attributes
    mutagenesis_factor_id
    mutagenesis_factor_attributes
    cassette_transmission_verified
    cassette_transmission_verified_auto_complete
    crsp_total_embryos_injected
    crsp_total_embryos_survived
    crsp_total_transfered
    crsp_no_founder_pups
    founder_num_assays
    assay_type
    founder_num_positive_results
    crsp_total_num_mutant_founders
    crsp_num_founders_selected_for_breading
    real_allele_id
    external_ref
    colonies_attributes
    experimental
  }

  READABLE_ATTRIBUTES = %w{
    id
    distribution_centres_formatted_display
    mi_plan_mutagenesis_via_crispr_cas9
    es_cell_marker_symbol
    marker_symbol
    es_cell_allele_symbol
    status_name
    status_dates
    mouse_allele_symbol_superscript
    mouse_allele_symbol
    phenotype_attempts_count
    pipeline_name
    allele_symbol
    blast_strain_mgi_accession
    blast_strain_mgi_name
    colony_background_strain_mgi_accession
    colony_background_strain_mgi_name
    test_cross_strain_mgi_accession
    test_cross_strain_mgi_name
    mgi_accession_id
    mutagenesis_factor_external_ref
    genotyped_confirmed_colony_names
    genotyped_confirmed_colony_phenotype_attempts_count
    genotype_confirmed_allele_symbols
    genotype_confirmed_distribution_centres

  } + FULL_ACCESS_ATTRIBUTES

  WRITABLE_ATTRIBUTES = %w{
  } + FULL_ACCESS_ATTRIBUTES

  attr_accessible(*WRITABLE_ATTRIBUTES)

  def status_name; status.name; end

  def status_dates
    retval = reportable_statuses_with_latest_dates
    retval.each do |status_name, date|
      retval[status_name] = date.to_s
    end
    return retval
  end

  def phenotype_attempts_count
    return 0 if self.colony.blank?
    self.colony.allele_modifications.length + self.colony.phenotyping_productions.length
  end

  def pipeline_name
    try(:es_cell).try(:pipeline).try(:name)
  end

  def genotyped_confirmed_colony_names
    return [] if (colonies.blank? && colony.blank?) || self.id.blank?
    return '[' + Colony.where("genotype_confirmed = true AND mi_attempt_id = #{self.id}").map{|c| c.name}.join(',') + ']'
  end

  def genotyped_confirmed_colony_phenotype_attempts_count
    return [] if (colonies.blank? && colony.blank?) || self.id.blank?
    return '[' + Colony.where("genotype_confirmed = true AND mi_attempt_id = #{self.id}").map{|c| c.phenotype_attempts_count}.join(',') + ']'
  end

  def genotype_confirmed_allele_symbols
    return [] if (colonies.blank? && colony.blank?) || self.id.blank?
    return '[' + Colony.where("genotype_confirmed = true AND mi_attempt_id = #{self.id}").map{|c| c.allele_symbol}.join(',') + ']'
  end

  def genotype_confirmed_distribution_centres
    return [] if (colonies.blank? && colony.blank?) || self.id.blank?
    return '[' + Colony.where("genotype_confirmed = true AND mi_attempt_id = #{self.id}").map{|c| c.distribution_centres.count > 0 ? c.distribution_centres_formatted_display : '[]'}.join(',') + ']'

  end
end

# == Schema Information
#
# Table name: mi_attempts
#
#  id                                              :integer          not null, primary key
#  es_cell_id                                      :integer
#  mi_date                                         :date             not null
#  status_id                                       :integer          not null
#  external_ref                                    :string(125)
#  updated_by_id                                   :integer
#  blast_strain_id                                 :integer
#  total_blasts_injected                           :integer
#  total_transferred                               :integer
#  number_surrogates_receiving                     :integer
#  total_pups_born                                 :integer
#  total_female_chimeras                           :integer
#  total_male_chimeras                             :integer
#  total_chimeras                                  :integer
#  number_of_males_with_0_to_39_percent_chimerism  :integer
#  number_of_males_with_40_to_79_percent_chimerism :integer
#  number_of_males_with_80_to_99_percent_chimerism :integer
#  number_of_males_with_100_percent_chimerism      :integer
#  colony_background_strain_id                     :integer
#  test_cross_strain_id                            :integer
#  date_chimeras_mated                             :date
#  number_of_chimera_matings_attempted             :integer
#  number_of_chimera_matings_successful            :integer
#  number_of_chimeras_with_glt_from_cct            :integer
#  number_of_chimeras_with_glt_from_genotyping     :integer
#  number_of_chimeras_with_0_to_9_percent_glt      :integer
#  number_of_chimeras_with_10_to_49_percent_glt    :integer
#  number_of_chimeras_with_50_to_99_percent_glt    :integer
#  number_of_chimeras_with_100_percent_glt         :integer
#  total_f1_mice_from_matings                      :integer
#  number_of_cct_offspring                         :integer
#  number_of_het_offspring                         :integer
#  number_of_live_glt_offspring                    :integer
#  mouse_allele_type                               :string(3)
#  report_to_public                                :boolean          default(TRUE), not null
#  is_active                                       :boolean          default(TRUE), not null
#  is_released_from_genotyping                     :boolean          default(FALSE), not null
#  comments                                        :text
#  created_at                                      :datetime
#  updated_at                                      :datetime
#  mi_plan_id                                      :integer          not null
#  genotyping_comment                              :string(512)
#  legacy_es_cell_id                               :integer
#  cassette_transmission_verified                  :date
#  cassette_transmission_verified_auto_complete    :boolean
#  mutagenesis_factor_id                           :integer
#  crsp_total_embryos_injected                     :integer
#  crsp_total_embryos_survived                     :integer
#  crsp_total_transfered                           :integer
#  crsp_no_founder_pups                            :integer
#  founder_pcr_num_assays                          :integer
#  founder_pcr_num_positive_results                :integer
#  founder_surveyor_num_assays                     :integer
#  founder_surveyor_num_positive_results           :integer
#  founder_t7en1_num_assays                        :integer
#  founder_t7en1_num_positive_results              :integer
#  crsp_total_num_mutant_founders                  :integer
#  crsp_num_founders_selected_for_breading         :integer
#  founder_loa_num_assays                          :integer
#  founder_loa_num_positive_results                :integer
#  allele_id                                       :integer
#  real_allele_id                                  :integer
#  founder_num_assays                              :integer
#  founder_num_positive_results                    :integer
#  assay_type                                      :text
#  experimental                                    :boolean          default(FALSE), not null
#
# Indexes
#
#  index_mi_attempts_on_colony_name  (external_ref) UNIQUE
#
