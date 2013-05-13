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
    },
    {
        name: 'is_active',
        defaultValue: true
    },
    {
        name: 'is_bespoke_allele',
        defaultValue: false
    },
    {
        name: 'es_qc_comment_name'
    },
    {
        name: 'completion_note'
    },
    {
        name: 'phenotype_only',
        defaultValue: false
    },
    {
        name: 'is_conditional_allele',
        defaultValue: false
    },
    {
        name: 'recovery',
        defaultValue: false
    },
    {
        name: 'is_deletion_allele',
        defaultValue: false
    },
    {
        name: 'is_cre_knock_in_allele',
        defaultValue: false
    },
    {
        name: 'is_cre_bac_allele',
        defaultValue: false
    },
    {
        name: 'is_conditional_allele',
        defaultValue: false
    },
    {
        name: 'conditional_tm1c',
        defaultValue: false
    },
    {
        name: 'ignore_available_mice',
        defaultValue: false
    },
    {
        name: 'comment'
    },
    {
        name: 'mi_attempts_count',
        readOnly: true,
        persist: false
    },
    {
        name: 'phenotype_attempts_count',
        readOnly: true,
        persist: false
    }

    ],

    proxy: Ext.create('Imits.data.Proxy', {
        resource: 'mi_plan'
    })
});
