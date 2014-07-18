Ext.define('Imits.widget.grid.MiAttemptRansackFiltersFeature', {
    extend: 'Imits.widget.grid.RansackFiltersFeature',
    alias: 'feature.mi_attempt_ransack_filters',

    encode: false,

    buildQuery: function (filters) {
        var params = this.callParent([filters]);
        var terms = window.MI_ATTEMPT_SEARCH_PARAMS.terms;

        if(!Ext.isEmpty(terms)) {
            terms = terms.split("\n");
            params['q[mi_plan_gene_marker_symbol_or_es_cell_name_or_external_ref_ci_in][]'] = terms;
        }

        return params;
    }
});
