Ext.define('Imits.widget.grid.MiPlanRansackFiltersFeature', {
    extend: 'Imits.widget.grid.RansackFiltersFeature',
    alias: 'feature.mi_plan_ransack_filters',

    encode: false,

    /** @private */
    constructor : function(config) {
        this.callParent([config]);

        var production_centre_name = window.USER_PRODUCTION_CENTRE;

        this.addFilter({
            type: 'string',
            dataIndex: 'production_centre_name',
            value: production_centre_name
        });
    }
});
