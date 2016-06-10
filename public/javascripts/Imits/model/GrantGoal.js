Ext.define('Imits.model.GrantGoal', {
    extend: 'Ext.data.Model',
    requires: ['Imits.data.Proxy'],

    fields: [
     {
         name: 'id',
         type: 'int',
         persist: false
     },
    {
        name: 'name'
    },
    {
        name: 'funding'
    },
    {
        name: 'consortium_name'
    },
    {
        name: 'production_centre_name'
    },
    {
        name: 'commence_date'
    },
    {
        name: 'end_date'
    },
    {
        name: 'grant_goal'
    }
    ],

    proxy: Ext.create('Imits.data.Proxy', {
        resource: 'grant'
    })
});
