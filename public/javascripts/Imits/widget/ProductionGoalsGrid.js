Ext.define('Imits.widget.ProductionGoalsGrid', {
    extend: 'Imits.widget.Grid',

    requires: [
    'Imits.model.ProductionGoal'
    ],

    title: 'Production Goals',
    iconCls: 'icon-grid',
    columnLines: true,

    store: {
        model: 'Imits.model.ProductionGoal',
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
        dataIndex: 'id',
        header: 'ID',
        readOnly: true,
        hidden: true
    },
    {
        header: 'Edit In Form',
        dataIndex: 'edit_link',
        renderer: function(value, metaData, record) {
            var id = record.getId();
            return Ext.String.format('<a href="{0}/production_goals/{1}">Edit in Form</a>', window.basePath, id);
        },
        sortable: false
    },
    {
        dataIndex: 'consortium_name',
        header: 'Consortium',
        readOnly: true
    },
    {
        dataIndex: 'year',
        header: 'Year',
        readOnly: true
    },
    {
        dataIndex: 'month',
        header: 'Month',
        readOnly: true
    },
    {
        dataIndex: 'mi_goal',
        header: 'MI Goal',
        readOnly: true
    },
    {
        dataIndex: 'gc_goal',
        header: 'GC Goal',
        readOnly: true
    }
    ]
});
