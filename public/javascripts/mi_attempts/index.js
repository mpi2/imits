Ext.define('Imits.model.MiAttempt', {
    extend: 'Ext.data.Model',
    fields: [
    {
        name: 'id',
        type: 'int'
    },
    {
        name: 'colony_name',
        type: 'string'
    },
    {
        name: 'es_cell_name',
        type: 'string',
        readOnly: true
    }
    ],

    proxy: {
        type: 'rest',
        url: '/mi_attempts',
        format: 'json',
        startParam: undefined,
        limitParam: 'per_page'
    }
});

Ext.onReady(function() {
    Ext.create('Ext.grid.Panel', {
        title: 'Micro-Injection Attempts',
        renderTo: 'mi-attempts-grid',
        store: {
            model: 'Imits.model.MiAttempt',
            autoLoad: true
        },
        columns: [
        {
            header: 'ID',
            dataIndex: 'id',
            hidden: true
        },
        {
            header: 'ES Cell Name',
            dataIndex: 'es_cell_name'
        },
        {
            header: 'Colony Name',
            dataIndex: 'colony_name'
        }
        ]
    });
});
