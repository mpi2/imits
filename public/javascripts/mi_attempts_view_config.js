var MI_ATTEMPTS_VIEW_CONFIG = {
    'transfer_details': [
    'blast_strain',
    'total_blasts_injected',
    'total_transferred',
    'number_surrogates_receiving'
    ],
    'litter_details': [
    'total_pups_born',
    'total_female_chimeras',
    'total_male_chimeras',
    'total_chimeras',
    'number_of_males_with_0_to_39_percent_chimerism',
    'number_of_males_with_40_to_79_percent_chimerism',
    'number_of_males_with_80_to_99_percent_chimerism',
    'number_of_males_with_100_percent_chimerism',
    ],
    'chimera_mating_details': [
    'emma_status',
    'test_cross_strain',
    'back_cross_strain',
    'date_chimeras_mated',
    'number_of_chimera_matings_attempted',
    'number_of_chimera_matings_successful',
    'number_of_chimeras_with_glt_from_cct',
    'number_of_chimeras_with_glt_from_genotyping',
    'number_of_chimeras_with_0_to_9_percent_glt',
    'number_of_chimeras_with_10_to_49_percent_glt',
    'number_of_chimeras_with_50_to_99_percent_glt',
    'number_of_chimeras_with_100_percent_glt',
    'total_f1_mice_from_matings',
    'number_of_cct_offspring',
    'number_of_het_offspring',
    'number_of_live_glt_offspring',
    'mouse_allele_name'
    ],
    'qc_details': [
    'qc_southern_blot__description',
    'qc_five_prime_lrpcr__description',
    'qc_five_prime_cassette_integrity__description',
    'qc_tv_backbone_assay__description',
    'qc_neo_count_qpcr__description',
    'qc_neo_sr_pcr__description',
    'qc_loa_qpcr__description',
    'qc_homozygous_loa_sr_pcr__description',
    'qc_lacz_sr_pcr__description',
    'qc_mutant_specific_sr_pcr__description',
    'qc_loxp_confirmation__description',
    'qc_three_prime_lr_pcr__description'
    ]
}

// Add common columns to each view
var commonColumns = [
'clone__clone_name',
'clone__marker_symbol',
'allele_name',
'mi_date',
'mi_attempt_status__description',
'colony_name',
'production_centre__name',
'distribution_centre__name'
]

var everythingView = [].concat(commonColumns);

for(var i in MI_ATTEMPTS_VIEW_CONFIG) {
    everythingView = everythingView.concat(MI_ATTEMPTS_VIEW_CONFIG[i]);
    MI_ATTEMPTS_VIEW_CONFIG[i] = commonColumns.concat(MI_ATTEMPTS_VIEW_CONFIG[i]);
}

MI_ATTEMPTS_VIEW_CONFIG['everything'] = everythingView;
