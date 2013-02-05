Ext.define('Imits.widget.NotificationsGrid', {
    extend: 'Imits.widget.Grid',

    requires: [
      'Imits.model.Notification',
      'Imits.widget.NotificationPane',
      'Imits.widget.grid.RansackFiltersFeature',
      'Imits.Util'
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

    features: [
    {
        ftype: 'ransack_filters',
        local: false
    }
    ],

    createNotification: function() {
        var self = this;
        var emailAddress = self.emailField.getSubmitValue();
        var geneField = self.geneField.getSubmitValue();

        if(!emailAddress || emailAddress && !emailAddress.length) {
            alert("You must enter a Email Address.");
            return
        }

        if(!geneField || geneField && !geneField.length) {
            alert("You must enter a gene marker symbol.");
            return
        }

        self.setLoading(true);

        var notificationRecord = Ext.create('Imits.model.Notification', {
            'contact_email' : emailAddress,
            'gene_marker_symbol' : geneField
        });

        notificationRecord.save({
            callback: function() {
                self.reloadStore();
                self.setLoading(false);

                self.geneField.setValue()
                self.emailField.setValue()
            }
        })
    },

    initComponent: function () {
      var self = this;

      self.callParent();

      self.addDocked(Ext.create('Ext.toolbar.Paging', {
          store: self.getStore(),
          dock: 'bottom',
          displayInfo: true
      }));

      self.notificationPane = Ext.create('Imits.widget.NotificationPane', {
          listeners: {
              'hide': {
                  fn: function () {
                      self.setLoading(false);
                  }
              }
          }
      });

      self.getView().on('cellmousedown',function(view, cell, cellIdx, record, row, rowIdx, eOpts){
        var id = record.data['id'];
        self.setLoading("Loading notification....");
        self.notificationPane.load(id);
      });

      self.geneField = Ext.create('Ext.form.field.ComboBox', {
        displayField: 'gene_name',
        store: window.GENE_OPTIONS,
        fieldLabel: 'Gene of interest',
        labelAlign: 'right',
        labelWidth: 100,
        queryMode: 'local',
        typeAhead: true
      });

      self.emailField = Ext.create('Ext.form.field.Text', {
        fieldLabel: 'Email address',
        name: 'email',
        labelWidth: 80,
        width:250,
        labelAlign: 'right'
      })

      self.addDocked(Ext.create('Ext.toolbar.Toolbar', {
          dock: 'top',
          items: [
            self.geneField,
            self.emailField,
            '  ',
            {
                id: 'register_interest_button',
                text: 'Register interest',
                cls:'x-btn-text-icon',
                iconCls: 'icon-add',
                grid: self,
                handler: function() {
                    self.createNotification();
                }
            }
         ]
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
      dataIndex: "gene_id",
      header: "Gene ID",
      hidden: true
    },
    {
      dataIndex: "gene_marker_symbol",
      header: "Gene",
      filter: {
        type: 'string'
      }
    },
    {
      dataIndex: "contact_id",
      header: "Contact ID",
      hidden: true
    },
    {
      dataIndex: "contact_email",
      header: "Contact",
      width:180,
      filter: {
        type: 'string'
      }
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
