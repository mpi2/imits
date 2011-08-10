Ext.define('Imits.model.MiAttempt', {
    extend: 'Ext.data.Model',
    fields: [
    {
        name: 'id',
        type: 'int',
        persist: false
    },
    {
        name: 'es_cell_name',
        persist: false
    },
    {
        name: 'es_cell_marker_symbol',
        persist: false
    },
    {
        name: 'es_cell_allele_symbol',
        persist: false
    },
    {
        name: 'mi_date',
        type: 'date'
    },
    {
        name: 'status',
        persist: false
    },
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

    proxy: Ext.create('Imits.data.Proxy', {
        resource: 'mi_attempt'
    })
});
