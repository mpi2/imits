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
'emma_status'
]

var everythingView = [].concat(commonColumns);

for(var i in MI_ATTEMPTS_VIEW_CONFIG) {
    everythingView = everythingView.concat(MI_ATTEMPTS_VIEW_CONFIG[i]);
    MI_ATTEMPTS_VIEW_CONFIG[i] = commonColumns.concat(MI_ATTEMPTS_VIEW_CONFIG[i]);
}

MI_ATTEMPTS_VIEW_CONFIG['everything'] = everythingView;
