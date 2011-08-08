Ext.define('Imits.model.MiAttempt', {
    extend: 'Ext.data.Model',
    fields: [
    {
        name: 'id',
        type: 'int'
    },
    'es_cell_name',
    'es_cell_marker_symbol',
    'es_cell_allele_symbol',
    {
        name: 'mi_date',
        type: 'date'
    },
    'status',
    'colony_name',
    'consortium_name',
    'production_centre_name',
    'distribution_centre_name',
    'deposited_material_name',
    'blast_strain_name',
    {
        name: 'total_blasts_injected',
        type: 'int'
    },

    {
        name: 'total_transferred',
        type: 'int'
    },

    {
        name: 'number_surrogates_receiving',
        type: 'int'
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
