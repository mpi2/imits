Ext.define('Imits.widget.ContactsGrid', {
    extend: 'Imits.widget.Grid',

    requires: [
      'Imits.model.Contact',
      'Imits.widget.grid.RansackFiltersFeature',
      'Imits.Util'
    ],

    title: 'Contacts',
    iconCls: 'icon-grid',
    columnLines: true,

    store: {
        model: 'Imits.model.Contact',
        autoLoad: true,
        autoSync: true,
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

    plugins: [
      Ext.create('Ext.grid.plugin.RowEditing', {
          autoCancel: false,
          clicksToEdit: 1
      })
    ],

    createContact: function() {
        var self = this;
        var emailAddress = self.emailField.getSubmitValue();

        if(!emailAddress || emailAddress && !emailAddress.length) {
            alert("You must enter a Email Address.");
            return
        }

        self.setLoading(true);

        var contactRecord = Ext.create('Imits.model.Contact', {
            'email' : emailAddress
        });

        contactRecord.save({
            callback: function() {
                self.reloadStore();
                self.setLoading(false);

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
              self.emailField,
              '  ',
              {
                  id: 'register_interest_button',
                  text: 'Create contact',
                  cls:'x-btn-text-icon',
                  iconCls: 'icon-add',
                  grid: self,
                  handler: function() {
                      self.createContact();
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
      dataIndex: "email",
      header: "Email address",
      width:300,
      filter: {
        type: 'string'
      },
      editor: 'textfield'
    },
    {
      xtype:'actioncolumn',
      width:21,
      items: [{
        icon: '../images/icons/delete.png',
        tooltip: 'Delete',
        handler: function(grid, rowIndex, colIndex) {
          var record = grid.getStore().getAt(rowIndex);
          
          if(confirm("Remove contact?"))
            grid.getStore().removeAt(rowIndex)

        }
      }]
    }
    ]
});
