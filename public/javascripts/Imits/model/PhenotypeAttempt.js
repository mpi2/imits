Ext.define('Imits.model.PhenotypeAttempt', {
    extend: 'Ext.data.Model',
    requires: ['Imits.data.Proxy'],

    fields: [
    {
        name: 'id',
        type: 'int',
        persist: false
    },
    {
        name: 'colony_name'
    },
    {
        name: 'consortium_name'
    },
    {
        name: 'production_centre_name'
    },
    {
        name: 'distribution_centres_formatted_display',
        readOnly: true
    },
    {
        name: 'mi_attempt_colony_name',
        readOnly: true,
        persist: false
    },
    {
        name: 'marker_symbol'
    },
    {
        name: 'is_active'
    },
    {
        name: 'status_name',
        persist: false,
        readOnly: true
    },
    {
        name: 'rederivation_started'
    },
    {
        name: 'rederivation_complete'
    },
    {
        name: 'deleter_strain_name'
    },
    {
        name: 'number_of_cre_matings_successful'
    },
    {
        name: 'phenotyping_started'
    },
    {
        name: 'phenotyping_complete'
    },
    {
        name: 'mi_plan_id',
        type: 'int'
    },
    {
        name: 'mgi_accession_id'
    },

    // QC Details
    'qc_southern_blot_result',
    'qc_five_prime_lr_pcr_result',
    'qc_five_prime_cassette_integrity_result',
    'qc_tv_backbone_assay_result',
    'qc_neo_count_qpcr_result',
    'qc_lacz_count_qpcr_result',
    'qc_neo_sr_pcr_result',
    'qc_loa_qpcr_result',
    'qc_homozygous_loa_sr_pcr_result',
    'qc_lacz_sr_pcr_result',
    'qc_mutant_specific_sr_pcr_result',
    'qc_loxp_confirmation_result',
    'qc_three_prime_lr_pcr_result',
    'qc_critical_region_qpcr_result',
    'qc_loxp_srpcr_result',
    'qc_loxp_srpcr_and_sequencing_result'

    ],

    proxy: Ext.create('Imits.data.Proxy', {
        resource: 'phenotype_attempt'
    })
});
