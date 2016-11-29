# encoding: utf-8

class Rest::EsCellMiAttemptSerializer
  include Serializable

  JSON_ATTRIBUTES = %w{
    id
    external_ref
    mi_date
    es_cell_name
    colony_name
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
    cassette_transmission_verified
    cassette_transmission_verified_auto_complete
    es_cell_allele_symbol
    mouse_allele_symbol_superscript
    mouse_allele_symbol
    pipeline_name
    privacy
  }

  def initialize(mi_attempt, options = {})
    @options = options
    @mi_attempt = mi_attempt
    @distribution_centres = mi_attempt.distribution_centres
  end

  def as_json
    json_hash = super(@mi_attempt, @options) do |serialized_hash|
      serialized_hash['distribution_centres_attributes'] = distribution_centres_attributes
    end

    return json_hash
  end

  def distribution_centres_attributes
    distribution_centres_hash = []
    @distribution_centres.each do |distribution_centre|
      distribution_centres_hash << Rest::DistributionCentreSerializer.new(distribution_centre, @options).as_json
    end

    return distribution_centres_hash
  end

end
