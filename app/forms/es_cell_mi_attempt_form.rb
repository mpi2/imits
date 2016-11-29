# encoding: utf-8
class EsCellMiAttemptForm
  include AcceptNestedAttributes

  WRITABLE_ATTRIBUTES = %w{
    external_ref
    mi_date
    es_cell_name
    colony_name
    mi_plan_id
    marker_symbol
    consortium_name
    production_centre_name
    blast_strain_name
    total_blasts_injected
    total_transferred
    number_surrogates_receiving
    total_pups_born
    total_female_chimeras
    total_male_chimeras
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
    cassette_transmission_verified
    cassette_transmission_verified_auto_complete
    mouse_allele_symbol_superscript
    mouse_allele_symbol
    privacy
  }

  WRITABLE_ATTRIBUTES.each do |attr|
    define_method(attr) do
        if @params.has_key?(attr)
          return @params[attr]
        else
          @form_model.send(attr)
      end
    end
  end

  def initialize(mi_attempt, params)
  	raise 'Please provide model and params' if mi_attempts.blank? || params.blank?
  	@form_model = mi_attempt
    
    # Store Form Objects populated from attributes params designed to update attributes in associated models
    @distribution_centres = []

    # params received
  	@params = params

    process_attributes_params
  end



end
