//Ext.Loader.setPath('Ext.ux', 'public/extjs/examples/ux');
Ext.define('Imits.widget.PhenotypeAttemptsGrid', {
    extend: 'Imits.widget.Grid',

    requires: [
    'Imits.model.PhenotypeAttempt',
    'Imits.widget.SimpleNumberField',
    'Imits.widget.SimpleCombo',
    'Imits.widget.QCCombo',
    'Imits.widget.grid.BoolGridColumn',
    'Imits.widget.grid.PhenotypeAttemptRansackFiltersFeature',
    'Imits.widget.grid.SimpleDateColumn'
//    'Ext.ux.grid.FiltersFeature'
    ],

    title: "Phenotype attempts",
    iconCls: 'icon-grid',
    columnLines: true,

    store: {
        model: 'Imits.model.PhenotypeAttempt',
        autoLoad: true,
        remoteSort: true,
        pageSize: 20
    },

    selType: 'rowmodel',

    features: [
    {
        ftype: 'phenotype_attempt_ransack_filters',
        local: false
    }
    ],

    initComponent: function () {
        var self = this;

        self.callParent();

        self.addDocked(Ext.create('Ext.toolbar.Paging', {
            store: self.getStore(),
            dock: 'bottom',
            displayInfo: true
        }));

    },

    columns: [
    {
        dataIndex: 'id',
        header: 'ID',
        readOnly: true,
        hidden: true,
        filter: {
            type: 'numeric'
        }
    },
    {
        dataIndex: 'colony_name',
        header: 'Phenotype colony name',
        readOnly: true,
        width: 150,
        filter: {
            type: 'string'
        }
    },
    {
        dataIndex: 'consortium_name',
        header: 'Consortium',
        readOnly: true,
        width: 115,
        filter: {
            type: 'list',
            options: window.PHENOTYPE_CONSORTIUM_OPTIONS
        }
    },
    {
        dataIndex: 'production_centre_name',
        header: 'Production centre name',
        readOnly: true,
        width: 150,
        filter: {
            type: 'list',
            options: window.PHENOTYPE_CENTRE_OPTIONS
        }
    },
    {
        dataIndex: 'mi_attempt_colony_name',
        header: 'MI attempt colony name',
        readOnly: true,
        width: 150,
        filter: {
            type: 'string',
            disabled: true
        }
    },
    {
        dataIndex: 'is_active',
        header: 'Active?',
        readOnly: true,
        xtype: 'boolgridcolumn',
        filter: {
            type: 'boolean'
        }
    },
    {
        dataIndex: 'rederivation_started',
        header: 'Rederivation started',
        readOnly: true,
        xtype: 'boolgridcolumn',
        width: 150,
        filter: {
            type: 'boolean'
        }
    },
    {
        dataIndex: 'rederivation_complete',
        header: 'Rederivation complete',
        readOnly: true,
        xtype: 'boolgridcolumn',
        width: 150,
        filter: {
            type: 'boolean'
        }
    },
    {
        dataIndex: 'number_of_cre_matings_started',
        header: 'Number of Cre matings started',
        readOnly: true,
        editor: 'simplenumberfield',
        width: 180,
        filter: {
            type: 'numeric'
        }
    },
    {
        dataIndex: 'number_of_cre_matings_successful',
        header: 'Number of Cre matings successful',
        readOnly: true,
        editor: 'simplenumberfield',
        width: 200,
        filter: {
            type: 'numeric'
        }
    },
    {
        dataIndex: 'phenotyping_started',
        header: 'Phenotyping started',
        readOnly: true,
        xtype: 'boolgridcolumn',
        width: 180,
        filter: {
            type: 'boolean'
        }
    },
    {
        dataIndex: 'phenotyping_complete',
        header: 'Phenotyping complete',
        readOnly: true,
        xtype: 'boolgridcolumn',
        width: 220,
        filter: {
            type: 'boolean'
        }
    }
    ]
});
