Ext.define('Imits.widget.grid.PhenotypeAttemptRansackFiltersFeature', {
    extend: 'Imits.widget.grid.RansackFiltersFeature',
    alias: 'feature.phenotype_attempt_ransack_filters',

    encode: false,

    buildQuery: function (filters) {
        var params = this.callParent([filters]);
        var terms = window.PHENOTYPE_ATTEMPT_SEARCH_PARAMS.terms;

        if(!Ext.isEmpty(terms)) {
            terms = terms.split("\n");
            params['q[colony_name_or_mi_plan_gene_marker_symbol_or_parent_colony_name_in][]'] = terms;
        }

        return params;
    }
});
