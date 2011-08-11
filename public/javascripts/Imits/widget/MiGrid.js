Ext.define('Imits.widget.MiGrid', {
    extend: 'Ext.grid.Panel',

    title: 'Micro-Injection Attempts',
    store: {
        model: 'Imits.model.MiAttempt',
        autoLoad: true,
        autoSync: true,
        remoteSort: true,

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

    selType: 'cellmodel',
    plugins: [
    Ext.create('Ext.grid.plugin.CellEditing', {
        autoCancel: false,
        clicksToEdit: 1
    })
    ],

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

        'litter_details': [
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
        ]
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
        this.generateColumns(config);
        this.callParent(arguments);
    },

    initComponent: function() {
        this.callParent();

        this.addDocked(Ext.create('Ext.toolbar.Paging', {
            store: this.getStore(),
            dock: 'bottom',
            displayInfo: true
        }));
    }
});
