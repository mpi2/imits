Ext.define('Imits.widget.grid.RansackFiltersFeature', {
    extend: 'Ext.ux.grid.FiltersFeature',
    alias: 'feature.ransack_filters',

    /**
     * @cfg {Boolean} encode
     * Unlike the base class, this parameter is totally ignored when
     * building a query
     */
    encode: false,

    buildQuerySingle: function (filter) {
        var param = {};
        switch (filter.data.type) {
            case 'numeric':
                if(filter.data.comparison != 'eq') {
                    param['q[' + filter.field + '_'+filter.data.comparison+']'] = filter.data.value;
                } else {
                    param['q[' + filter.field + '_in][]'] = filter.data.value;
                }
                break;
            case 'string':
                if(filter.field == 'id') {
                    param['q[' + filter.field + '_in][]'] = filter.data.value.split(',');
                }else {
                    param['q[' + filter.field + '_ci_in][]'] = filter.data.value;
                }
                break;
            case 'list':
                if (filter.field == 'no_consortium_id') {
                  if (filter.data.value == '1'){
                    param['q[' + 'consortium_id_null]' ] = 1;
                  }
                  else {
                    param['q[' + 'consortium_id_not_null]' ] = 1;
                  }
                }
                else {
                  param['q[' + filter.field + '_ci_in][]'] = filter.data.value;
                }
                break;

            case 'boolean':
                param['q[' + filter.field + '_eq]'] = filter.data.value;
                break;

            case 'date':
                var dateParts = filter.data.value.split('/');
                param['q[' + filter.field + '_' + filter.data.comparison + ']'] = [dateParts[2]+'-'+dateParts[0]+'-'+dateParts[1]];
                break;
        }
        return param;
    },

    buildQuery: function (filters) {
        var params = {};

        var self = this;

        Ext.each(filters, function (filter) {
            var p = self.buildQuerySingle(filter);
            for (var i in p) {
                params[i] = p[i];
            }
        });

        return params;
    },

    cleanParams: function (params) {
        var regex, key;
        regex = new RegExp('^q\\[\\w+_ci_in\\]$');
        for (key in params) {
            if (regex.test(key)) {
                delete params[key];
            }
        }
    }
});
