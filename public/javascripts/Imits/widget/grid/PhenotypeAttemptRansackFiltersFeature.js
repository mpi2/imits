Ext.define('Imits.widget.grid.PhenotypeAttemptRansackFiltersFeature', {
    extend: 'Imits.widget.grid.RansackFiltersFeature',
    alias: 'feature.phenotype_attempt_ransack_filters',

    encode: false,

    buildQuery: function (filters) {
        var params = this.callParent([filters]);
        var terms = window.PHENOTYPE_ATTEMPT_SEARCH_PARAMS.terms;

        if(!Ext.isEmpty(terms)) {
            terms = terms.split("\n");
            params['q[marker_symbol_ci_in][]'] = terms;
        }

        return params;
    }
});
