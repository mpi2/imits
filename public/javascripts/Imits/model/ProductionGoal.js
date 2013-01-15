Ext.define('Imits.model.ProductionGoal', {
    extend: 'Ext.data.Model',
    requires: ['Imits.data.Proxy'],

    fields: [
    {
        name: 'id',
        type: 'int',
        persist: false
    },
    {
        name: 'consortium_name'
    },
    {
        name: 'year'
    },
    {
        name: 'month'
    },
    {
        name: 'mi_goal'
    },
    {
        name: 'gc_goal'
    }

    ],

    proxy: Ext.create('Imits.data.Proxy', {
        resource: 'production_goal'
    })
});
