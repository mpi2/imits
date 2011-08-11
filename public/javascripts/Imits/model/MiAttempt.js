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
    {
        name: 'consortium_name',
        persist: false
    },
    {
        name: 'production_centre_name',
        persist: false
    },
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
    },
    {
        name: 'total_pups_born',
        type: 'int'
    },
    {
        name: 'total_female_chimeras',
        type: 'int'
    },
    {
        name: 'total_male_chimeras',
        type: 'int'
    },
    {
        name: 'total_chimeras',
        type: 'int',
        persist: false
    },
    {
        name: 'number_of_males_with_0_to_39_percent_chimerism',
        type: 'int'
    },
    {
        name: 'number_of_males_with_40_to_79_percent_chimerism',
        type: 'int'
    },
    {
        name: 'number_of_males_with_80_to_99_percent_chimerism',
        type: 'int'
    },
    {
        name: 'number_of_males_with_100_percent_chimerism',
        type: 'int'
    },

    // Chimera Mating Details
    {
        name: 'emma_status'
    },
    {
        name: 'test_cross_strain_name'
    },
    {
        name: 'colony_background_strain_name'
    },
    {
        name: 'date_chimeras_mated',
        type: 'date'
    },
    {
        name: 'number_of_chimera_matings_attempted',
        type: 'int'
    },
    {
        name: 'number_of_chimera_matings_successful',
        type: 'int'
    },
    {
        name: 'number_of_chimeras_with_glt_from_cct',
        type: 'int'
    },
    {
        name: 'number_of_chimeras_with_glt_from_genotyping',
        type: 'int'
    },
    {
        name: 'number_of_chimeras_with_0_to_9_percent_glt',
        type: 'int'
    },
    {
        name: 'number_of_chimeras_with_10_to_49_percent_glt',
        type: 'int'
    },
    {
        name: 'number_of_chimeras_with_50_to_99_percent_glt',
        type: 'int'
    },
    {
        name: 'number_of_chimeras_with_100_percent_glt',
        type: 'int'
    },
    {
        name: 'total_f1_mice_from_matings',
        type: 'int'
    },
    {
        name: 'number_of_cct_offspring',
        type: 'int'
    },
    {
        name: 'number_of_het_offspring',
        type: 'int'
    },
    {
        name: 'number_of_live_glt_offspring',
        type: 'int'
    },
    {
        name: 'mouse_allele_type',
        readOnly: true
    },
    {
        name: 'mouse_allele_symbol',
        readOnly: true
    }

    ],

    proxy: Ext.create('Imits.data.Proxy', {
        resource: 'mi_attempt'
    })
});
