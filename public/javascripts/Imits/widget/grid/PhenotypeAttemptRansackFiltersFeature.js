Ext.define('Imits.widget.grid.PhenotypeAttemptRansackFiltersFeature', {
    extend: 'Imits.widget.grid.RansackFiltersFeature',
    alias: 'feature.phenotype_attempt_ransack_filters',

     buildQuerySingle: function(filter) {
        if(filter.data.type != 'string' && filter.data.type != 'numeric') {
            return this.callParent([filter]);
        }
        alert('PhenotypeAttemptRansackFiltersFeature');
        var param = {};
        switch (filter.data.type) {
            case 'string':
                //param['q[' + filter.field + '_matches]'] = filter.data.value;
                param['q[' + filter.field + '_matches]'] = filter.data.value;
                break;

            case 'numeric':
                //alert("FOUND: " + filter.data.value);
                //alert("FOUND: " + filter.toString());
                //param['q[' + filter.field + '_eq]'] = filter.data.value;
                param['q[' + filter.field + '_' + filter.data.comparison + ']'] = filter.data.value;
                break;

           //default:
            //    param = this.callParent([filter]);

        }
        //if(! param) {
        //    param = this.callParent([filter]);
        //}
        return param ;
     }


    //buildQuery: function(filters) {
    //
    //    alert("PhenotypeAttemptRansackFiltersFeature");
    //
    //    if(filter.data.type != 'string' && filter.data.type != 'numeric') {
    //        return this.callParent([filters]);
    //    }
    //
    //    var params = {};
    //    Ext.each(filters, function(filter) {
    //        switch (filter.data.type) {
    //        case 'string':
    //            //params['q[' + filter.field + '_matches]'] = filter.data.value;
    //            params['q[' + filter.field + '_matches]'] = filter.data.value;
    //            break;
    //
    //        case 'numeric':
    //            //alert("FOUND: " + filter.data.value);
    //            //alert("FOUND: " + filter.toString());
    //            //params['q[' + filter.field + '_eq]'] = filter.data.value;
    //            params['q[' + filter.field + '_' + filter.data.comparison + ']'] = filter.data.value;
    //            break;
    //        }
    //    });
    //
    //    return params;
    //}

});
