Ext.define('Imits.widget.SolrUpdateQueueItemsGrid', {
    extend: 'Imits.widget.Grid',

    requires: [
    'Imits.widget.grid.RansackFiltersFeature',
    'Imits.model.SolrUpdateQueueItem',
    'Imits.Util'
    ],

    title: 'Solr Update Queue Items',
    iconCls: 'icon-grid',
    columnLines: true,

    store: {
        model: 'Imits.model.SolrUpdateQueueItem',
        autoLoad: true,
        remoteSort: true,
        remoteFilter: true,
        pageSize: 200
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
        readOnly: true,
        width: 60
    },
    {
        dataIndex: 'reference',
        header: 'Reference',
        readOnly: true,
        flex: 1,
        renderer: function (value, metaData, record) {
            var ref = record.get('reference');
            var editUrl = Ext.String.format('{0}/{1}s/{2}', window.basePath, ref.type, ref.id);
            if(ref.type == "allele") {
              var historyUrl = '/targ_rep' + editUrl + '/history';
            } else {
              var historyUrl = editUrl + '/history';
            }
            
            return Ext.String.format('<a href="{0}">{1} / {2}</a> (<a href="{3}">audit history</a>)', editUrl, ref.type, ref.id, historyUrl);
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
    },
    {
        header: '',
        xtype: 'actioncolumn',
        width: 48,
        items: [
        {
            icon: window.basePath + '/images/icons/resultset_next.png',
            tooltip: 'Run now',
            handler: function (grid, rowIndex, colIndex) {
                var item = grid.getStore().getAt(rowIndex);
                var itemId = item.get('id');
                Ext.Msg.confirm('Run item?',
                    'Run item ' + itemId + '?',
                    function (buttonName) {
                        if (buttonName === 'yes') {
                            grid.setLoading('Running item ' + itemId);

                            Ext.Ajax.request({
                                method: 'POST',
                                params: {
                                    'authenticity_token': window.authenticityToken
                                    },
                                url: window.basePath + '/solr_update/queue/items/' + itemId + '/run.json',
                                success: function () {
                                    grid.getStore().remove(item);
                                },
                                failure: function (response) {
                                    Imits.Util.handleErrorResponse(response);
                                },
                                callback: function () {
                                    grid.setLoading(false);
                                }
                            });
                        }
                    });
            }
        },
        {
            icon: window.basePath + '/images/icons/cancel.png',
            tooltip: 'Delete',
            handler: function (grid, rowIndex, colIndex) {
                var item = grid.getStore().getAt(rowIndex);
                Ext.Msg.confirm('Delete item?',
                    'Delete item ' + item.get('id') + '?',
                    function (buttonName) {
                        if (buttonName === 'yes') {
                            grid.setLoading('Deleting item ' + item.get('id'));
                            item.destroy({
                                success: function () {
                                    grid.getStore().remove(item);
                                },

                                callback: function () {
                                    grid.setLoading(false);
                                }

                            });
                        }
                    });
            }
        }
        ]
    },
    {
        header: '',
        width: 80,
        renderer: function (value, metaData, record) {
            var ref = record.get('reference');
            return Ext.String.format('<a href="{0}/search?q=type:{1}+id:{2}">{3}</a>',
                window.SOLR_ALLELE_URL, ref.type, ref.id, 'SOLR view');
        }
    }
    ]
});
