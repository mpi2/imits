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
        name: 'default_sub_project_name'
    },
    {
        name: 'priority_name'
    },
    {
        name: 'es_cell_qc_intent',
        type: 'boolean'
    },
    {
        name: 'es_cell_mi_attempt_intent',
        type: 'boolean'
    },
    {
        name: 'nuclease_mi_attempt_intent',
        type: 'boolean'
    },

    {
        name: 'mouse_allele_modification_intent',
        type: 'boolean'
    },
    {
        name: 'phenotyping_intent',
        type: 'boolean'
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
    },
    {
        name: 'conflicts',
        readOnly: true,
        persist: false
    },
    {
        name: 'conflict_summary',
        readOnly: true,
        persist: false
    }
    ],

    proxy: Ext.create('Imits.data.Proxy', {
        resource: 'plan'
    })
});
