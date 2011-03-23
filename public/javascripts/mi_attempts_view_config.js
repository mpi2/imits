var MI_ATTEMPTS_VIEW_CONFIG = {
    'transfer-details': [
    'blast-strain',
    'num-blasts',
    'num-transferred',
    'no-surrogates-received'
    ],
    'litter-details': [
    'number-born',
    'number-female-chimeras',
    'number-male-chimeras',
    'total-chimeras',
    'number-male-100-percent',
    'number-male-gt-80-percent',
    'number-male-40-to-80-percent',
    'number-male-lt-40-percent'
    ]
}

// Add common columns to each view
var commonColumns = [
'clone-name',
'gene-symbol',
'allele-name',
'actual-mi-date',
'status',
'colony-name',
'distribution-centre-name',
'emma-status'
]

var everythingView = [].concat(commonColumns);

for(var i in MI_ATTEMPTS_VIEW_CONFIG) {
    everythingView = everythingView.concat(MI_ATTEMPTS_VIEW_CONFIG[i]);
    MI_ATTEMPTS_VIEW_CONFIG[i] = commonColumns.concat(MI_ATTEMPTS_VIEW_CONFIG[i]);
}

MI_ATTEMPTS_VIEW_CONFIG['everything'] = everythingView;
