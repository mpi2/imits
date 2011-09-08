Ext.define('Imits.widget.grid.RansackFiltersFeature', {
    extend: 'Ext.ux.grid.FiltersFeature',
    alias: 'feature.ransack_filters',

    /**
     * @cfg {Boolean} encode
     * Unlike the base class, this parameter is totally ignored when
     * building a query
     */
    encode: false,

    /** @private */
    constructor : function(config) {
        this.callParent([config]);

        var production_centre_name = window.MI_ATTEMPT_SEARCH_PARAMS.production_centre_name;
        var status = window.MI_ATTEMPT_SEARCH_PARAMS.status;
        this.terms = window.MI_ATTEMPT_SEARCH_PARAMS.terms.split("\n");

        if(!Ext.isEmpty(production_centre_name)) {
            this.addFilter({
                type: 'string',
                dataIndex: 'production_centre_name',
                value: production_centre_name
            });
        }

        if(!Ext.isEmpty(status)) {
            this.addFilter({
                type: 'string',
                dataIndex: 'status',
                value: status
            });
        }
    },

    buildQuery: function(filters) {
        var params = {};

        Ext.each(filters, function(filter) {
            switch (filter.data.type) {
                case 'string':
                case 'list':
                    params['q[' + filter.field + '_ci_in][]'] = filter.data.value;
                    break;

                case 'boolean':
                    params['q[' + filter.field + '_eq]'] = filter.data.value;
                    break;

                case 'date':
                    var dateParts = filter.data.value.split('/');
                    params['q[' + filter.field + '_' + filter.data.comparison + ']'] = [dateParts[2]+'-'+dateParts[0]+'-'+dateParts[1]];
                    break;
            }
        });

        if(!Ext.isEmpty(this.terms)) {
            params['q[es_cell_marker_symbol_or_es_cell_name_or_colony_name_ci_in][]'] = this.terms;
        }

        return params;
    },

    cleanParams: function(params) {
        var regex, key;
        regex = new RegExp('^q\\[\\w+_ci_in\\]$');
        for (key in params) {
            if (regex.test(key)) {
                delete params[key];
            }
        }
    }
});
