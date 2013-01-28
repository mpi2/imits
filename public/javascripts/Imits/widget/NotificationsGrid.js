Ext.define('Imits.widget.NotificationsGrid', {
    extend: 'Imits.widget.Grid',

    requires: [
      'Imits.model.Notification',
      'Imits.widget.NotificationPane',
      'Imits.widget.grid.RansackFiltersFeature'
    ],

    title: 'Notifications',
    iconCls: 'icon-grid',
    columnLines: true,

    store: {
        model: 'Imits.model.Notification',
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

        //self.addListener('afterrender', function () {
        //    self.filters.createFilters();
        //});

        self.notificationPane = Ext.create('Imits.widget.NotificationPane', {
            listeners: {
                'hide': {
                    fn: function () {
                        self.setLoading(false);
                    }
                }
            }
        });

        //self.addListener('itemclick', function (theView, record, item, index, event, eventOptions) {
        //    var target = Ext.get(event.getTarget());
        //    if (target.dom.nodeName.toLowerCase() !== 'a') {
        //        var id = record.data['id'];
        //        self.setLoading("Loading notification....");
        //        self.notificationPane.load(id);
        //    }
        //});

        self.getView().on('cellmousedown',function(view, cell, cellIdx, record, row, rowIdx, eOpts){
          var id = record.data['id'];
          self.setLoading("Loading notification....");
          self.notificationPane.load(id);
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
      dataIndex: "gene_id",
      header: "Gene ID",
      hidden: true
    },
    {
      dataIndex: "gene_marker_symbol",
      header: "Gene"
    },
    {
      dataIndex: "contact_id",
      header: "Contact ID",
      hidden: true
    },
    {
      dataIndex: "contact_email",
      header: "Contact",
      width:180
    },
    {
      dataIndex: "last_email_sent",
      xtype: 'datecolumn',
      format: "Y-m-d H:i:s",
      header: "Last email sent",
      width:130
    },
    {
      dataIndex: "welcome_email_sent",
      xtype: 'datecolumn',
      format: "Y-m-d H:i:s",
      header: "Welcome email sent",
      width:130
    },
    {
      dataIndex: "updated_at",
      xtype: 'datecolumn',
      format: "Y-m-d H:i:s",
      header: "Last updated",
      hidden: true,
      width:130
    },
    {
      xtype:'actioncolumn',
      width:21,
      items: [{
          icon: '../images/icons/time_go.png',
          tooltip: 'Resend',
          handler: function(grid, rowIndex, colIndex) {
              var record = grid.getStore().getAt(rowIndex);
              var id = record.data['id'];
              if(confirm("Are you sure you want to resend this notification?")) {

                // Fix for sessions
                Ext.Ajax.request({
                    url: document.location.pathname + '/' + id + '/retry.json',
                    method: 'PUT',
                    params: {
                      'authenticity_token': window.authenticityToken
                    },
                    success: function(response){
                        var text = response.responseText;
                        // process server response here
                    }
                });

              }
          }
      }]
    }
    ]
});
