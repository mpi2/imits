Ext.define('Imits.model.TrackingGoal', {
    extend: 'Ext.data.Model',
    requires: ['Imits.data.Proxy'],

    fields: [
    {
        name: 'id',
        type: 'int',
        persist: false
    },
    {
        name: 'production_centre_name'
    },
    {
        name: 'year'
    },
    {
        name: 'month'
    },
    {
        name: 'goal'
    },
    {
        name: 'goal_type'
    }
    ],
    

    proxy: Ext.create('Imits.data.Proxy', {
        resource: 'tracking_goal'
    })
});
