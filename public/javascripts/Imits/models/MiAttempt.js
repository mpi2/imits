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
