Ext.define('Imits.widget.grid.PhenotypeAttemptRansackFiltersFeature', {
    extend: 'Imits.widget.grid.RansackFiltersFeature',
    alias: 'feature.phenotype_attempt_ransack_filters',

     buildQuerySingle: function(filter) {
        if(filter.data.type != 'string' && filter.data.type != 'numeric') {
            return this.callParent([filter]);
        }
        var param = {};
        switch (filter.data.type) {
            case 'string':
                param['q[' + filter.field + '_matches]'] = filter.data.value;
                break;

            case 'numeric':
                param['q[' + filter.field + '_' + filter.data.comparison + ']'] = filter.data.value;
                break;
        }
        return param ;
     }
});
