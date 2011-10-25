Ext.define('Imits.model.MiPlan', {
    extend: 'Ext.data.Model',
    requires: ['Imits.data.Proxy'],

    fields: [
    {
        name: 'id',
        type: 'int',
        persist: false
    },
    {
        name: 'marker_symbol',
        persist: false
    },
    {
        name: 'consortium_name',
        persist: false
    },
    {
        name: 'production_centre_name',
        persist: false
    },
    {
        name: 'status',
        persist: false
    },
    {
        name: 'priority',
        persist: false
    }
    ],

    proxy: Ext.create('Imits.data.Proxy', {
        resource: 'mi_plan'
    })
});
