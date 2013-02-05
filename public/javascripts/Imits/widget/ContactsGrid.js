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
