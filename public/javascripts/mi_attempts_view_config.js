var MI_ATTEMPTS_VIEW_CONFIG = {
    'transfer-details': [
    'blast-strain',
    'total-blasts-injected',
    'total-transferred',
    'no-surrogates-received'
    ],
    'litter-details': [
    'total-pups-born',
    'total-female-chimeras',
    'total-male-chimeras',
    'total-chimeras',
    'male-chimerism levels 100%'
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
'distribution-centre',
'emma-status'
]

var everythingView = [].concat(commonColumns);

for(var i in MI_ATTEMPTS_VIEW_CONFIG) {
    everythingView = everythingView.concat(MI_ATTEMPTS_VIEW_CONFIG[i]);
    MI_ATTEMPTS_VIEW_CONFIG[i] = commonColumns.concat(MI_ATTEMPTS_VIEW_CONFIG[i]);
}

MI_ATTEMPTS_VIEW_CONFIG['everything'] = everythingView;
