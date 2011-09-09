Ext.define('Imits.widget.grid.RansackFiltersFeature', {
    extend: 'Ext.ux.grid.FiltersFeature',
    alias: 'feature.ransack_filters',

    /**
     * @cfg {Boolean} encode
     * Unlike the base class, this parameter is totally ignored when
     * building a query
     */
    encode: false,

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
