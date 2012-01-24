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
        name: 'marker_symbol'
    },
    {
        name: 'consortium_name'
    },
    {
        name: 'production_centre_name'
    },
    {
        name: 'status_name'
    },
    {
        name: 'priority_name'
    },
    {
        name: 'sub_project_name'
    },
    {
        name: 'number_of_es_cells_starting_qc'
    },
    {
        name: 'number_of_es_cells_passing_qc'
    },
    {
        name: 'withdrawn',
        defaultValue: false
    }
    ],

    proxy: Ext.create('Imits.data.Proxy', {
        resource: 'mi_plan'
    })
});
