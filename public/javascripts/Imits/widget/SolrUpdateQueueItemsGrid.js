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
    },

    columns: [
    {
        dataIndex: 'id',
        header: 'ID',
        readOnly: true
    },
    {
        dataIndex: 'reference',
        header: 'Reference',
        readOnly: true,
        width: 150,
        renderer: function(value, metaData, record) {
            var ref = record.get('reference');
            return Ext.String.format('{0} / {1}', ref.type, ref.id);
        }
    },
    {
        dataIndex: 'action',
        header: 'Action',
        readOnly: true,
        width: 60,
        filter: {
            type: 'list',
            options: ['update', 'delete']
        }
    },
    {
        dataIndex: 'created_at',
        xtype: 'datecolumn',
        format: 'd-m-Y H:i:s',
        header: 'Created At',
        readOnly: true,
        width: 125
    }
    ]
});
