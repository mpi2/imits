# encoding: utf-8

class Grid::MiAttemptSerializer
  include Serializable

  JSON_ATTRIBUTES = %w{
    id
    external_ref
    mi_date
    es_cell_name
    es_cell_marker_symbol
    es_cell_allele_symbol
    colony_name
    mouse_allele_type
    mouse_allele_symbol_superscript
    mouse_allele_symbol
    mi_plan_id
    marker_symbol
    mgi_accession_id
    consortium_name
    production_centre_name
    status_name
    status_dates
    blast_strain_name
    blast_strain_mgi_accession
    blast_strain_mgi_name
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
    colony_background_strain_mgi_accession
    colony_background_strain_mgi_name
    test_cross_strain_name
    test_cross_strain_mgi_accession
    test_cross_strain_mgi_name
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
    cassette_transmission_verified
    cassette_transmission_verified_auto_complete
    pipeline_name
    crsp_total_embryos_injected
    crsp_total_embryos_survived
    crsp_total_transfered
    crsp_no_founder_pups
    crsp_num_founders_selected_for_breading
    mrna_nuclease
    mrna_nuclease_concentration
    protein_nuclease
    protein_nuclease_concentration
    delivery_method
    voltage
    number_of_pulses
    crsp_embryo_transfer_day
    crsp_embryo_2_cell
    assay_type
    founder_num_assays
    experimental
    privacy
  }

  def initialize(mi_attempt)
    @mi_attempt = mi_attempt
    @distribution_centres = mi_attempt.distribution_centres
  end

  def genotyped_confirmed_colony_names
    return [] if (@mi_attempt.colonies.blank? && @mi_attempt.colony.blank?) || @mi_attempt.id.blank?
    return '[' + Colony.where("genotype_confirmed = true AND mi_attempt_id = #{@mi_attempt.id}").map{|c| c.name}.join(',') + ']'
  end

  def genotyped_confirmed_colony_phenotype_attempts_count
    return [] if (@mi_attempt.colonies.blank? && @mi_attempt.colony.blank?) || @mi_attempt.id.blank?
    return '[' + Colony.where("genotype_confirmed = true AND mi_attempt_id = #{@mi_attempt.id}").map{|c| c.phenotype_attempts_count}.join(',') + ']'
  end

  def genotype_confirmed_allele_symbols
    return [] if (@mi_attempt.colonies.blank? && @mi_attempt.colony.blank?) || @mi_attempt.id.blank?
    return '[' + Colony.where("genotype_confirmed = true AND mi_attempt_id = #{@mi_attempt.id}").map{|c| c.allele_symbol}.join(',') + ']'
  end

  def genotype_confirmed_distribution_centres
    return [] if (@mi_attempt.colonies.blank? && @mi_attempt.colony.blank?) || @mi_attempt.id.blank?
    return '[' + Colony.where("genotype_confirmed = true AND mi_attempt_id = #{@mi_attempt.id}").map{|c| c.distribution_centres.count > 0 ? c.distribution_centres_formatted_display : '[]'}.join(',') + ']'
  end

  def mi_plan_mutagenesis_via_crispr_cas9
    if !@mi_attempt.mi_plan.blank?
      @mi_attempt.mi_plan.mutagenesis_via_crispr_cas9
    else
      nil
    end
  end

  def as_json
    json_hash = super(@mi_attempt)
    json_hash['genotyped_confirmed_colony_names'] = genotyped_confirmed_colony_names
    json_hash['genotyped_confirmed_colony_phenotype_attempts_count'] = genotyped_confirmed_colony_phenotype_attempts_count
    json_hash['genotype_confirmed_allele_symbols'] = genotype_confirmed_allele_symbols
    json_hash['genotype_confirmed_distribution_centres'] = genotype_confirmed_distribution_centres
    json_hash['mi_plan_mutagenesis_via_crispr_cas9'] = mi_plan_mutagenesis_via_crispr_cas9
    return json_hash
  end

end


#  FULL_ACCESS_ATTRIBUTES = %w{
#    es_cell_name
#    mi_date
#    colony_name
#    consortium_name
#    production_centre_name
#    parent_colony_name
#    blast_strain_name
#    total_blasts_injected
#    total_transferred
#    number_surrogates_receiving
#    total_pups_born
#    total_female_chimeras
#    total_male_chimeras
#    total_chimeras
#    number_of_males_with_0_to_39_percent_chimerism
#    number_of_males_with_40_to_79_percent_chimerism
#    number_of_males_with_80_to_99_percent_chimerism
#    number_of_males_with_100_percent_chimerism
#    colony_background_strain_name
#    test_cross_strain_name
#    date_chimeras_mated
#    number_of_chimera_matings_attempted
#    number_of_chimera_matings_successful
#    number_of_chimeras_with_glt_from_cct
#    number_of_chimeras_with_glt_from_genotyping
#    number_of_chimeras_with_0_to_9_percent_glt
#    number_of_chimeras_with_10_to_49_percent_glt
#    number_of_chimeras_with_50_to_99_percent_glt
#    number_of_chimeras_with_100_percent_glt
#    total_f1_mice_from_matings
#    number_of_cct_offspring
#    number_of_het_offspring
#    number_of_live_glt_offspring
#    mouse_allele_type
#    qc_southern_blot_result
#    qc_five_prime_lr_pcr_result
#    qc_five_prime_cassette_integrity_result
#    qc_tv_backbone_assay_result
#    qc_neo_count_qpcr_result
#    qc_lacz_count_qpcr_result
#    qc_neo_sr_pcr_result
#    qc_loa_qpcr_result
#    qc_homozygous_loa_sr_pcr_result
#    qc_lacz_sr_pcr_result
#    qc_mutant_specific_sr_pcr_result
#    qc_loxp_confirmation_result
#    qc_three_prime_lr_pcr_result
#    qc_critical_region_qpcr_result
#    qc_loxp_srpcr_result
#    qc_loxp_srpcr_and_sequencing_result
#    report_to_public
#    is_active
#    is_released_from_genotyping
#    comments
#    genotyping_comment
#    mi_plan_id
#    mutagenesis_factor_id
#    cassette_transmission_verified
#    cassette_transmission_verified_auto_complete
#    mrna_nuclease
#    mrna_nuclease_concentration
#    protein_nuclease
#    protein_nuclease_concentration
#    delivery_method
#    voltage
#    number_of_pulses 
#    crsp_total_embryos_injected
#    crsp_total_embryos_survived
#    crsp_total_transfered
#    crsp_no_founder_pups
#    founder_num_assays
#    assay_type
#    crsp_embryo_transfer_day 
#    crsp_embryo_2_cell 
#    crsp_num_founders_selected_for_breading
#    real_allele_id
#    external_ref
#    experimental
#    distribution_centres_attributes
#    colonies_attributes
#    reagents_attributes
#    mutagenesis_factor_attributes
#    g0_screens_attributes
#    status_stamps_attributes
#    privacy
#  }
#
#  READABLE_ATTRIBUTES = %w{
#    id
#    distribution_centres_formatted_display
#    mi_plan_mutagenesis_via_crispr_cas9
#    es_cell_marker_symbol
#    marker_symbol
#    es_cell_allele_symbol
#    status_name
#    status_dates
#    mouse_allele_symbol_superscript
#    mouse_allele_symbol
#    phenotype_attempts_count
#    pipeline_name
#    allele_symbol
#    blast_strain_mgi_accession
#    blast_strain_mgi_name
#    colony_background_strain_mgi_accession
#    colony_background_strain_mgi_name
#    test_cross_strain_mgi_accession
#    test_cross_strain_mgi_name
#    mgi_accession_id
#    mutagenesis_factor_external_ref
#    genotyped_confirmed_colony_names
#    genotyped_confirmed_colony_phenotype_attempts_count
#    genotype_confirmed_allele_symbols
#    genotype_confirmed_distribution_centres
#
#  }
