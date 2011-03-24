var MI_ATTEMPTS_VIEW_CONFIG = {
    'transfer_details': [
    'blast_strain',
    'num_blasts',
    'num_transferred',
    'no_surrogates_received'
    ],
    'litter_details': [
    'number_born',
    'number_female_chimeras',
    'number_male_chimeras',
    'total_chimeras',
    'number_male_100_percent',
    'number_male_gt_80_percent',
    'number_male_40_to_80_percent',
    'number_male_lt_40_percent'
    ],
    'chimera_mating_details': [
    'emma_status',
    'test_cross_strain',
    'back_cross_strain',
    'number_chimera_mated',
    'number_chimera_mating_success',
    'number_with_cct',
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
'distribution_centre_name',
]

var everythingView = [].concat(commonColumns);

for(var i in MI_ATTEMPTS_VIEW_CONFIG) {
    everythingView = everythingView.concat(MI_ATTEMPTS_VIEW_CONFIG[i]);
    MI_ATTEMPTS_VIEW_CONFIG[i] = commonColumns.concat(MI_ATTEMPTS_VIEW_CONFIG[i]);
}

MI_ATTEMPTS_VIEW_CONFIG['everything'] = everythingView;
