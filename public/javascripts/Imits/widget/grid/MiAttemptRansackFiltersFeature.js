Ext.define('Imits.widget.grid.MiAttemptRansackFiltersFeature', {
    extend: 'Imits.widget.grid.RansackFiltersFeature',
    alias: 'feature.mi_attempt_ransack_filters',

    encode: false,

    /** @private */
    constructor : function (config) {
        this.callParent([config]);

        var production_centre_name = window.MI_ATTEMPT_SEARCH_PARAMS.production_centre_name;
        var statusName = window.MI_ATTEMPT_SEARCH_PARAMS.status_name;

        if(!Ext.isEmpty(production_centre_name)) {
            this.addFilter({
                type: 'string',
                dataIndex: 'production_centre_name',
                value: production_centre_name
            });
        }

        if(!Ext.isEmpty(statusName)) {
            this.addFilter({
                type: 'string',
                dataIndex: 'status_name',
                value: statusName
            });
        }
    },

    buildQuery: function (filters) {
        var params = this.callParent([filters]);
        var terms = window.MI_ATTEMPT_SEARCH_PARAMS.terms;

        if(!Ext.isEmpty(terms)) {
            terms = terms.split("\n");
            params['q[es_cell_marker_symbol_or_es_cell_name_or_colony_name_ci_in][]'] = terms;
        }

        return params;
    }
});
