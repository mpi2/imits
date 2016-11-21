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
        name: 'genotyped_confirmed_colony_names',
        persist: false
    },
    {
        name: 'genotyped_confirmed_colony_phenotype_attempts_count',
        persist: false
    },
    {
        name: 'genotype_confirmed_allele_symbols',
        persist: false
    },
    {
        name: 'genotype_confirmed_distribution_centres',
        persist: false
    },
    {
        name: 'consortium_name'
    },
    {
        name: 'production_centre_name'
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
        name: 'mouse_allele_type'
    },
    {
        name: 'mouse_allele_symbol'
    },

    // QC Details
    {
        name: 'qc_southern_blot_result'
    },
    {
        name: 'qc_five_prime_lr_pcr_result'
    },
    {
        name: 'qc_five_prime_cassette_integrity_result'
    },
    {
        name: 'qc_tv_backbone_assay_result'
    },
    {
        name: 'qc_neo_count_qpcr_result'
    },
    {
        name: 'qc_lacz_count_qpcr_result'
    },
    {
        name: 'qc_neo_sr_pcr_result'
    },
    {
        name: 'qc_loa_qpcr_result'
    },
    {
        name: 'qc_homozygous_loa_sr_pcr_result'
    },
    {
        name: 'qc_lacz_sr_pcr_result'
    },
    {
        name: 'qc_mutant_specific_sr_pcr_result'
    },
    {
        name: 'qc_loxp_confirmation_result'
    },
    {
        name: 'qc_three_prime_lr_pcr_result'
    },
    {
        name: 'qc_critical_region_qpcr_result'
    },
    {
        name: 'qc_loxp_srpcr_result'
    },
    {
        name: 'qc_loxp_srpcr_and_sequencing_result'
    },
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
    {
        name: 'mi_plan_id',
        type: 'int',
        persist: false
    },
    {
        name: 'mgi_accession_id',
        persist: false
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
        name: 'crsp_num_founders_selected_for_breading',
        type: 'int'
    },    
    {
        name: 'mrna_nuclease'
    },
    {
        name: 'mrna_nuclease_concentration',
        type: 'float'
    },
    {
        name: 'protein_nuclease'
    },
    {
        name: 'protein_nuclease_concentration',
        type: 'float'
    },
    {
        name: 'delivery_method'
    },
    {
        name: 'voltage',
        type: 'int'
    },
    {
        name: 'number_of_pulses',
        type: 'int'
    },
    {
        name: 'crsp_embryo_transfer_day'
    },
    {
        name: 'crsp_embryo_2_cell',
        type: 'int'
    },
    {
        name: 'assay_type'
    },
    {
        name: 'founder_num_assays',
        type: 'int'
    },
    {
        name: 'experimental',
        type: 'boolean'
    },
    {
        name: 'privacy' 
    },

    ],

    proxy: Ext.create('Imits.data.Proxy', {
        resource: 'mi_attempt'
    })
});
