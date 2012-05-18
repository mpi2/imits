Ext.define('Imits.widget.grid.PhenotypeAttemptRansackFiltersFeature', {
    extend: 'Imits.widget.grid.RansackFiltersFeature',
    alias: 'feature.phenotype_attempt_ransack_filters',

    encode: false,

    /** @private */
    constructor : function (config) {
        this.callParent([config]);

        var production_centre_name = window.PHENOTYPE_ATTEMPT_SEARCH_PARAMS.production_centre_name;

        if(!Ext.isEmpty(production_centre_name)) {
            this.addFilter({
                type: 'string',
                dataIndex: 'production_centre_name',
                value: production_centre_name
            });
        }

    },

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
