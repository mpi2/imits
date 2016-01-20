Ext.define('Imits.model.Plan', {
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
        name: 'es_cell_qc_intent',
        readOnly: true,
        persist: false
    },
    {
        name: 'es_cell_mi_attempt_intent',
        readOnly: true,
        persist: false
    },
    {
        name: 'crispr_mi_attempt_intent',
        readOnly: true,
        persist: false
    },

    {
        name: 'mouse_allele_modification_intent',
        readOnly: true,
        persist: false
    },
    {
        name: 'phenotyping_intent',
        readOnly: true,
        persist: false
    },
    {
        name: 'mi_attempts_count',
        readOnly: true,
        persist: false
    },
    {
        name: 'mouse_allele_modification_count',
        readOnly: true,
        persist: false
    },
    {
        name: 'phenotyping_count',
        readOnly: true,
        persist: false
    }
    ],

    proxy: Ext.create('Imits.data.Proxy', {
        resource: 'plan'
    })
});
