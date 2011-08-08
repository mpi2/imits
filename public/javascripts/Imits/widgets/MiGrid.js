Ext.define('Imits.widgets.MiGrid', {
    extend: 'Ext.grid.Panel',

    title: 'Micro-Injection Attempts',
    store: {
        model: 'Imits.model.MiAttempt',
        autoLoad: true
    },

    groupedColumns: {
        'common' : [
        {
            dataIndex: 'id',
            header: 'ID',
            readOnly: true,
            hidden: true
        },
        {
            header: 'Edit In Form',
            dataIndex: 'id',
            renderer: function(miId) {
                return Ext.String.format('<a href="{0}/mi_attempts/{1}">Edit in Form</a>', window.basePath, miId);
            }
        },
        {
            dataIndex: 'es_cell_name',
            header: 'ES Cell',
            readOnly: true
        },
        {
            dataIndex: 'es_cell_marker_symbol',
            header: 'Marker Symbol',
            width: 75,
            readOnly: true
        },
        {
            dataIndex: 'es_cell_allele_symbol',
            header: 'Allele symbol',
            readOnly: true
        },
        {
            dataIndex: 'mi_date',
            header: 'MI Date'
        },
        {
            dataIndex: 'status',
            header: 'Status',
            width: 150,
            readOnly: true
        },
        {
            dataIndex: 'colony_name',
            header: 'Colony Name'
        },
        {
            dataIndex: 'consortium_name',
            header: 'Consortium',
            readOnly: true
        },
        {
            dataIndex: 'production_centre_name',
            header: 'Production Centre',
            readOnly: true
        },
        {
            dataIndex: 'distribution_centre_name',
            header: 'Distribution Centre',
            readOnly: true
        },
        {
            dataIndex: 'deposited_material_name',
            header: 'Deposited Material',
            readOnly: true
        }
        ],

        'transferDetails': [
        {
            dataIndex: 'deposited_material_name',
            header: 'Deposited Material',
            readOnly: true
        },
        {
            dataIndex: 'blast_strain_name',
            header: 'Blast Strain',
            readOnly: true
        },
        {
            dataIndex: 'total_blasts_injected',
            header: 'Total Blasts Injected'
        },
        {
            dataIndex: 'total_transferred',
            header: 'Total Transferred'
        },
        {
            dataIndex: 'number_surrogates_receiving',
            header: '# Surrogates Receiving'
        }
        ]
    },

    generateColumns: function(config) { // private
        var columns = [];
        Ext.Object.each(this.groupedColumns, function(viewName, viewColumns) {
            Ext.Array.each(viewColumns, function(column) {
                columns.push(column);
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
