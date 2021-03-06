Ext.define('Imits.model.Gene', {
    extend: 'Ext.data.Model',
    requires: ['Imits.data.Proxy'],

fields: [
    {
        name: 'id',
        type: 'int',
        readOnly: true
    },

    {
        name: 'marker_symbol',
        readOnly: true
    },

    {
        name: 'mgi_accession_id',
        readOnly: true
    },

    {
        name: 'ikmc_projects_count',
        readOnly: true
    },

    {
        name: 'pretty_print_types_of_cells_available',
        readOnly: true
    },

    {
        name: 'non_assigned_mi_plans',
        readOnly: true
    },

    {
        name: 'assigned_mi_plans',
        readOnly: true
    },

    {
        name: 'pretty_print_aborted_mi_attempts',
        readOnly: true
    },

    {
        name: 'pretty_print_mi_attempts_in_progress',
        readOnly: true
    },

    {
        name: 'pretty_print_mi_attempts_genotype_confirmed',
        readOnly: true
    },

    {
        name: 'pretty_print_phenotype_attempts',
        readOnly: true
    }

    ],
    proxy: Ext.create('Imits.data.Proxy', {
        resource: 'gene'
    })
});
