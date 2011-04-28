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
    'date_chimera_mated',
    'number_of_chimera_matings_attempted',
    'number_of_chimera_matings_successful',
    'number_of_chimeras_with_glt_from_cct',
    'chimeras_with_glt_from_genotyp',
    'number_lt_10_percent_glt',
    'number_btw_10_50_percent_glt',
    'number_gt_50_percent_glt',
    'number_100_percent_glt',
    'total_f1_mice',
    'number_with_cct',
    'number_het_offspring',
    'number_live_glt_offspring',
    'mouse_allele_name'
    ],
    'qc_details': [
    'qc_southern_blot',
    'qc_five_prime_lr_pcr',
    'qc_five_prime_cass_integrity',
    'qc_tv_backbone_assay',
    'qc_neo_count_qpcr',
    'qc_neo_sr_pcr',
    'qc_loa_qpcr',
    'qc_homozygous_loa_sr_pcr',
    'qc_lacz_sr_pcr',
    'qc_mutant_specific_sr_pcr',
    'qc_loxp_confirmation',
    'qc_three_prime_lr_pcr'
    ]
}

// Add common columns to each view
var commonColumns = [
'clone_name',
'gene_symbol',
'allele_name',
'actual_mi_date',
'status',
'colony_name',
'distribution_centre_name'
]

var everythingView = [].concat(commonColumns);

for(var i in MI_ATTEMPTS_VIEW_CONFIG) {
    everythingView = everythingView.concat(MI_ATTEMPTS_VIEW_CONFIG[i]);
    MI_ATTEMPTS_VIEW_CONFIG[i] = commonColumns.concat(MI_ATTEMPTS_VIEW_CONFIG[i]);
}

MI_ATTEMPTS_VIEW_CONFIG['everything'] = everythingView;
