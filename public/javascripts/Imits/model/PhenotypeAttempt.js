Ext.define('Imits.model.PhenotypeAttempt', {
    extend: 'Ext.data.Model',
    requires: ['Imits.data.Proxy'],

    fields: [
    {
        name: 'id',
        type: 'int',
        persist: false
    },
    {
        name: 'colony_name'
    },
    {
        name: 'consortium_name'
    },
    {
        name: 'production_centre_name'
    },
    {
        name: 'mi_attempt_colony_name'
    },
    {
        name: 'marker_symbol'
    },
    {
        name: 'is_active'
    },
    {
        name: 'status_name'
    },
    {
        name: 'rederivation_started'
    },
    {
        name: 'rederivation_complete'
    },
    {
        name: 'deleter_strain_name'
    },
    {
        name: 'number_of_cre_matings_successful'
    },
    {
        name: 'phenotyping_started'
    },
    {
        name: 'phenotyping_complete'
    }
    ],

    proxy: Ext.create('Imits.data.Proxy', {
        resource: 'phenotype_attempt'
    })
});
