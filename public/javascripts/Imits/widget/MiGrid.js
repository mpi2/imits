Ext.define('Imits.widget.MiGrid', {
    extend: 'Ext.grid.Panel',

    title: 'Micro-Injection Attempts',
    store: {
        model: 'Imits.model.MiAttempt',
        autoLoad: true,
        autoSync: true,
        remoteSort: true,
        pageSize: 20,

        // TODO Remove when dirty flag bug goes away
        listeners: {
            'update': {
                fn: function(store, record) {
                    // Inspired by "http://www.sencha.com/forum/showthread.php?133767-Store.sync()-does-not-update-dirty-flag&p=608485&viewfull=1#post608485"
                    if (record.dirty) {
                        record.commit();
                    }
                }
            }
        }
    },

    selType: 'rowmodel',

    plugins: [
    Ext.create('Ext.grid.plugin.RowEditing', {
        autoCancel: false,
        clicksToEdit: 1
    })
    ],

    manageResize: function() {
        var windowHeight = window.innerHeight - 30;
        if(!windowHeight) {
            windowHeight = document.documentElement.clientHeight - 30;
        }
        var newGridHeight = windowHeight - this.getEl().getTop();
        if(newGridHeight < 200) {
            newGridHeight = 200;
        }
        this.setHeight(newGridHeight);
        this.doLayout();
    },

    generateColumns: function(config) { // private
        var columns = [];
        Ext.Object.each(this.groupedColumns, function(viewName, viewColumns) {
            Ext.Array.each(viewColumns, function(column) {
                var existing;
                Ext.each(columns, function(i) {
                    if(i.dataIndex == column.dataIndex && i.header == column.header) {
                        existing = i;
                    }
                });
                if(!existing) {
                    columns.push(column);
                }
            });
        });

        config.columns = columns;
    },

    constructor: function(config) {
        if(config == undefined) {
            config = {}
        }
        this.generateColumns(config);
        this.callParent([config]);
    },

    initComponent: function() {
        this.callParent();

        this.addDocked(Ext.create('Ext.toolbar.Paging', {
            store: this.getStore(),
            dock: 'bottom',
            displayInfo: true
        }));
    },

    groupedColumns: {
        'common': [
        {
            dataIndex: 'id',
            header: 'ID',
            readOnly: true
        },
        {
            header: 'Edit In Form',
            dataIndex: 'id',
            renderer: function(miId) {
                return Ext.String.format('<a href="{0}/mi_attempts/{1}">Edit in Form</a>', window.basePath, miId);
            },
            sortable: false
        },
        {
            dataIndex: 'es_cell_name',
            header: 'ES Cell',
            readOnly: true,
            sortable: false
        },
        {
            dataIndex: 'es_cell_marker_symbol',
            header: 'Marker Symbol',
            width: 75,
            readOnly: true,
            sortable: false
        },
        {
            dataIndex: 'es_cell_allele_symbol',
            header: 'Allele symbol',
            readOnly: true,
            sortable: false
        },
        {
            dataIndex: 'mi_date',
            header: 'MI Date',
            editor: {
                xtype: 'datefield',
                format: 'd-m-Y'
            },
            renderer: Ext.util.Format.dateRenderer('d-m-Y')
        },
        {
            dataIndex: 'status',
            header: 'Status',
            width: 150,
            readOnly: true,
            sortable: false
        },
        {
            dataIndex: 'colony_name',
            header: 'Colony Name',
            editor: 'textfield'
        },
        {
            dataIndex: 'consortium_name',
            header: 'Consortium',
            readOnly: true,
            sortable: false
        },
        {
            dataIndex: 'production_centre_name',
            header: 'Production Centre',
            readOnly: true,
            sortable: false
        },
        {
            dataIndex: 'distribution_centre_name',
            header: 'Distribution Centre',
            readOnly: true,
            sortable: false
        },
        {
            dataIndex: 'deposited_material_name',
            header: 'Deposited Material',
            readOnly: true,
            sortable: false
        }
        ],

        'transferDetails': [
        {
            dataIndex: 'blast_strain_name',
            header: 'Blast Strain',
            readOnly: true,
            sortable: false
        },
        {
            dataIndex: 'total_blasts_injected',
            header: 'Total Blasts Injected',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'total_transferred',
            header: 'Total Transferred',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_surrogates_receiving',
            header: '# Surrogates Receiving',
            editor: 'simplenumberfield'
        }
        ],

        'litterDetails': [
        {
            dataIndex: 'total_pups_born',
            header: 'Total Pups Born',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'total_female_chimeras',
            header: 'Total Female Chimeras',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'total_male_chimeras',
            header: 'Total Male Chimeras',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'total_chimeras',
            header: 'Total Female Chimeras',
            readOnly: true
        },
        {
            dataIndex: 'number_of_males_with_100_percent_chimerism',
            header: '100% Male Chimerism Levels',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_males_with_80_to_99_percent_chimerism',
            header: '99-80% Male Chimerism Levels',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_males_with_40_to_79_percent_chimerism',
            header: '79-40% Male Chimerism Levels',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_males_with_0_to_39_percent_chimerism',
            header: '39-0% Male Chimerism Levels',
            editor: 'simplenumberfield'
        }
        ],

        'chimeraMatingDetails': [
        {
            dataIndex: 'emma_status',
            header: 'EMMA Status',
            readOnly: true,
            sortable: false
        },
        {
            dataIndex: 'test_cross_strain_name',
            header: 'Test Cross Strain',
            readOnly: true,
            sortable: false
        },
        {
            dataIndex: 'colony_background_strain_name',
            header: 'Colony Background Strain',
            readOnly: true,
            sortable: false
        },
        {
            dataIndex: 'date_chimeras_mated',
            header: 'Date Chimeras Mated',
            editor: {
                xtype: 'datefield',
                format: 'd-m-Y'
            },
            renderer: Ext.util.Format.dateRenderer('d-m-Y')
        },
        {
            dataIndex: 'number_of_chimera_matings_attempted',
            header: '# Chimera Mating Attempted',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_chimera_matings_successful',
            header: '# Chimera Matings Successful',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_chimeras_with_glt_from_cct',
            header: '# Chimeras with Germline Transmission from CCT',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_chimeras_with_glt_from_genotyping',
            header: 'No. Chimeras with Germline Transmission from Genotyping',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_chimeras_with_0_to_9_percent_glt',
            header: '# Chimeras with 0-9% GLT',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_chimeras_with_10_to_49_percent_glt',
            header: '# Chimeras with 10-49% GLT',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_chimeras_with_50_to_99_percent_glt',
            header: 'No. Chimeras with 50-99% GLT',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_chimeras_with_100_percent_glt',
            header: 'No. Chimeras with 100% GLT',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'total_f1_mice_from_matings',
            header: 'Total F1 Mice from Matings',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_cct_offspring',
            header: '# Coat Colour Transmission Offspring',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_het_offspring',
            header: '# Het Offspring',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_live_glt_offspring',
            header: '# Live GLT Offspring',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'mouse_allele_type',
            header: 'Mouse Allele Type',
            readOnly: true
        },
        {
            dataIndex: 'mouse_allele_symbol',
            header: 'Mouse Allele Symbol',
            readOnly: true
        }
        ]
    }
// END groupedColumns - ALWAYS keep at bottom of file for easier organization

});
