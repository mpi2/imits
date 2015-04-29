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
        name: 'consortium_name'
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
        name: 'crispr_goal'
    },
    {
        name: 'goal_type'
    },
    {
        name: 'no_consortium_id',
        readOnly: true,
        persist: false
    }
    ],


    proxy: Ext.create('Imits.data.Proxy', {
        resource: 'tracking_goal'
    })
});
