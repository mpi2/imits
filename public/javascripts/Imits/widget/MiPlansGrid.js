Ext.define('Imits.widget.MiPlansGrid', {
    extend: 'Imits.widget.Grid',

    requires: [
    'Imits.model.MiPlan',
    'Imits.widget.grid.MiPlanRansackFiltersFeature',
    'Imits.widget.MiPlanEditor'
    ],

    title: "Your genes",
    iconCls: 'icon-grid',
    columnLines: true,

    store: {
        model: 'Imits.model.MiPlan',
        autoLoad: true,
        remoteSort: true,
        remoteFilter: true,
        pageSize: 25
    },

    selType: 'rowmodel',


    features: [
    {
        ftype: 'mi_plan_ransack_filters',
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

        self.miPlanEditor = Ext.create('Imits.widget.MiPlanEditor', {
            listeners: {
                'hide': {
                    fn: function() {
                        self.reloadStore();
                        self.setLoading(false);
                    }
                }
            }
        });

        self.addListener('itemclick', function(theView, record) {
            var id = record.data['id'];
            self.setLoading("Editing gene interest....");
            self.miPlanEditor.edit(id);
        });
    },

    columns: [
    {
        dataIndex: 'marker_symbol',
        header: 'Marker Symbol',
        readOnly: true,
        sortable: false,
        filter: {
            type: 'string'
        }
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
        width: 115,
        filter: {
            type: 'list',
            options: window.CONSORTIUM_OPTIONS
        }
    },
    {
        dataIndex: 'production_centre_name',
        header: 'Production Centre',
        readOnly: true,
        width: 115,
        filter: {
            type: 'list',
            options: window.CENTRE_OPTIONS
        }
    },
    {
        dataIndex: 'priority_name',
        header: 'Priority',
        readOnly: true,
        filter: {
            type: 'list',
            options: window.PRIORITY_OPTIONS
        }
    },
    {
        dataIndex: 'status_name',
        header: 'Status',
        readOnly: true,
        flex: 1,
        filter: {
            type: 'list',
            options: window.STATUS_OPTIONS
        }
    }
    ]
});
