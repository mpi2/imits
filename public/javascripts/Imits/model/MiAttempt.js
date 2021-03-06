Ext.define('Imits.model.MiAttempt', {
    extend: 'Ext.data.Model',
    requires: ['Imits.data.Proxy'],

    fields: [
    {
        name: 'id',
        type: 'int',
        persist: false
    },
    {
        name: 'es_cell_name',
        persist: false
    },
    {
        name: 'es_cell_marker_symbol',
        persist: false
    },
    {
        name: 'marker_symbol',
        persist: false
    },
    {
        name: 'es_cell_allele_symbol',
        persist: false
    },
    {
        name: 'mi_date',
        type: 'date'
    },
    {
        name: 'status_name',
        persist: false
    },
    {
        name: 'mi_plan_mutagenesis_via_crispr_cas9',
        persist: false
    },
    {
        name: 'colony_name'
    },
    {
        name: 'genotyped_confirmed_colony_names'
    },
    {
        name: 'genotyped_confirmed_colony_phenotype_attempts_count'
    },
    {
        name: 'genotype_confirmed_allele_symbols'
    },
    {
        name: 'genotype_confirmed_distribution_centres'
    },
    {
        name: 'consortium_name'
    },
    {
        name: 'production_centre_name'
    },
    {
        name: 'distribution_centres_attributes'
    },
    {
        name: 'distribution_centres_formatted_display',
        readOnly: true
    },
    {
        name: 'blast_strain_name'
    },
    {
        name: 'total_blasts_injected',
        type: 'int'
    },
    {
        name: 'total_transferred',
        type: 'int'
    },
    {
        name: 'number_surrogates_receiving',
        type: 'int'
    },
    {
        name: 'total_pups_born',
        type: 'int'
    },
    {
        name: 'total_female_chimeras',
        type: 'int'
    },
    {
        name: 'total_male_chimeras',
        type: 'int'
    },
    {
        name: 'total_chimeras',
        type: 'int',
        persist: false
    },
    {
        name: 'number_of_males_with_0_to_39_percent_chimerism',
        type: 'int'
    },
    {
        name: 'number_of_males_with_40_to_79_percent_chimerism',
        type: 'int'
    },
    {
        name: 'number_of_males_with_80_to_99_percent_chimerism',
        type: 'int'
    },
    {
        name: 'number_of_males_with_100_percent_chimerism',
        type: 'int'
    },

    // Chimera Mating Details
    {
        name: 'emma_status'
    },
    {
        name: 'test_cross_strain_name'
    },
    {
        name: 'colony_background_strain_name'
    },
    {
        name: 'date_chimeras_mated',
        type: 'date'
    },
    {
        name: 'number_of_chimera_matings_attempted',
        type: 'int'
    },
    {
        name: 'number_of_chimera_matings_successful',
        type: 'int'
    },
    {
        name: 'number_of_chimeras_with_glt_from_cct',
        type: 'int'
    },
    {
        name: 'number_of_chimeras_with_glt_from_genotyping',
        type: 'int'
    },
    {
        name: 'number_of_chimeras_with_0_to_9_percent_glt',
        type: 'int'
    },
    {
        name: 'number_of_chimeras_with_10_to_49_percent_glt',
        type: 'int'
    },
    {
        name: 'number_of_chimeras_with_50_to_99_percent_glt',
        type: 'int'
    },
    {
        name: 'number_of_chimeras_with_100_percent_glt',
        type: 'int'
    },
    {
        name: 'total_f1_mice_from_matings',
        type: 'int'
    },
    {
        name: 'number_of_cct_offspring',
        type: 'int'
    },
    {
        name: 'number_of_het_offspring',
        type: 'int'
    },
    {
        name: 'number_of_live_glt_offspring',
        type: 'int'
    },
    {
        name: 'mouse_allele_type',
        readOnly: true
    },
    {
        name: 'mouse_allele_symbol',
        readOnly: true
    },

    // QC Details
//    {
//        name: 'qc_southern_blot_result'
//    },
//    {
//        name: 'qc_five_prime_lr_pcr_result'
//    },
//    {
//        name: 'qc_five_prime_cassette_integrity_result'
//    },
//    {
//        name: 'qc_tv_backbone_assay_result'
//    },
//    {
//        name: 'qc_neo_count_qpcr_result'
//    },
//    {
//        name: 'qc_lacz_count_qpcr_result'
//    },
//    {
//        name: 'qc_neo_sr_pcr_result'
//    },
//    {
//        name: 'qc_loa_qpcr_result'
//    },
//    {
//        name: 'qc_homozygous_loa_sr_pcr_result'
//    },
//    {
//        name: 'qc_lacz_sr_pcr_result'
//    },
//    {
//        name: 'qc_mutant_specific_sr_pcr_result'
//    },
//    {
//        name: 'qc_loxp_confirmation_result'
//    },
//    {
//        name: 'qc_three_prime_lr_pcr_result'
//    },
//    {
//        name: 'qc_critical_region_qpcr_result'
//    },
//    {
//        name: 'qc_loxp_srpcr_result'
//    },
//    {
//        name: 'qc_loxp_srpcr_and_sequencing_result'
//    },
    {
        name: 'report_to_public',
        type: 'boolean'
    },
    {
        name: 'is_active',
        type: 'boolean'
    },
    {
        name: 'is_released_from_genotyping',
        type: 'boolean'
    },
    {   name: 'phenotype_attempts_count',
        type: 'int',
        readOnly: true,
        persist: false
    },
    {
        name: 'mi_plan_id',
        type: 'int'
    },
    {
        name: 'mgi_accession_id'
    },

    // Crispr transfer details
    {
        name: 'crsp_total_embryos_injected',
        type: 'int'
    },
    {
        name: 'crsp_total_embryos_survived',
        type: 'int'
    },
    {
        name: 'crsp_total_transfered',
        type: 'int'
    },

    // Crispr Founder Details
    {
        name: 'crsp_no_founder_pups',
        type: 'int'
    },
    {
        name: 'founder_pcr_num_assays',
        type: 'int'
    },
    {
        name: 'founder_pcr_num_positive_results',
        type: 'int'
    },
    {
        name: 'founder_surveyor_num_assays',
        type: 'int'
    },
    {
        name: 'founder_surveyor_num_positive_results',
        type: 'int'
    },
    {
        name: 'founder_t7en1_num_assays',
        type: 'int'
    },
    {
        name: 'founder_t7en1_num_positive_results',
        type: 'int'
    },
    {
        name: 'founder_loa_num_assays',
        type: 'int'
    },
    {
        name: 'founder_loa_num_positive_results',
        type: 'int'
    },
    {
        name: 'crsp_total_num_mutant_founders',
        type: 'int'
    },
    {
        name: 'crsp_num_founders_selected_for_breading',
        type: 'int'
    },

    ],

    proxy: Ext.create('Imits.data.Proxy', {
        resource: 'mi_attempt'
    })
});
