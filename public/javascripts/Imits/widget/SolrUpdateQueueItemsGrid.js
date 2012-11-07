Ext.define('Imits.widget.SolrUpdateQueueItemsGrid', {
    extend: 'Imits.widget.Grid',

    requires: [
    'Imits.widget.grid.RansackFiltersFeature',
    'Imits.model.SolrUpdateQueueItem'
    ],

    title: 'Solr Update Queue Items',
    iconCls: 'icon-grid',
    columnLines: true,

    store: {
        model: 'Imits.model.SolrUpdateQueueItem',
        autoLoad: true,
        remoteSort: true,
        remoteFilter: true,
        pageSize: 20
    },

    selType: 'rowmodel',

    features: [
    {
        ftype: 'ransack_filters',
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

        self.addListener('itemclick', function (theView, record) {
            var id = record.data['id'];
            self.setLoading("Editing plan....");
            self.setLoading(false);
        });
    },

    columns: [
    {
        dataIndex: 'id',
        header: 'ID',
        readOnly: true,
        hidden: true
    },
    {
        dataIndex: 'action',
        header: 'Action',
        readOnly: true,
        filter: {
            type: 'string'
        }
    }
    ]
});
