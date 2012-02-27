Ext.define('Imits.widget.PhenotypeAttemptsGrid', {
    extend: 'Imits.widget.Grid',

    requires: [
    'Imits.model.PhenotypeAttempt',
    'Imits.widget.grid.BoolGridColumn',
    'Imits.widget.SimpleNumberField'
    ],

    title: "Phenotype attempts",
    iconCls: 'icon-grid',
    columnLines: true,

    store: {
        model: 'Imits.model.PhenotypeAttempt',
        autoLoad: true,
        remoteSort: true,
        remoteFilter: true,
        pageSize: 20
    },

    selType: 'rowmodel',

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
        dataIndex: 'colony_name',
        header: 'Phenotype colony name',
        readOnly: true
    },
    {
        dataIndex: 'id',
        header: 'ID',
        readOnly: true,
        hidden: true
    },
    {
        dataIndex: 'consortium_name',
        header: 'Consortium',
        readOnly: true,
        width: 115
    },
    {
        dataIndex: 'production_centre_name',
        header: 'Production centre name',
        readOnly: true,
        width: 150
    },
    {
        dataIndex: 'mi_attempt_colony_name',
        header: 'MI attempt colony name',
        readOnly: true,
        width: 115
    },
    {
        dataIndex: 'is_active',
        header: 'Active?',
        readOnly: true,
        xtype: 'boolgridcolumn'
    },
    {
        dataIndex: 'rederivation_started',
        header: 'Rederivation started',
        readOnly: true,
        xtype: 'boolgridcolumn'
    },
    {
        dataIndex: 'rederivation_complete',
        header: 'Rederivation complete',
        readOnly: true,
        xtype: 'boolgridcolumn'
    },
    {
        dataIndex: 'number_of_cre_matings_started',
        header: 'Number of Cre matings started',
        readOnly: true,
        editor: 'simplenumberfield'
    },
    {
        dataIndex: 'number_of_cre_matings_successful',
        header: 'Number of Cre matings successful',
        readOnly: true,
        editor: 'simplenumberfield'
    },
    {
        dataIndex: 'phenotyping_started',
        header: 'Phenotyping started',
        readOnly: true,
        xtype: 'boolgridcolumn'
    },
    {
        dataIndex: 'phenotyping_complete',
        header: 'Phenotyping complete',
        readOnly: true,
        xtype: 'boolgridcolumn'
    }
    ]
});
