Ext.define('Imits.widget.StrainsGrid', {
    extend: 'Imits.widget.Grid',

    requires: [
      'Imits.model.Strain',
      'Imits.widget.grid.RansackFiltersFeature',
      'Imits.Util'
    ],

    title: 'Strains',
    iconCls: 'icon-grid',
    columnLines: true,

    store: {
        model: 'Imits.model.Strain',
        autoLoad: true,
        autoSync: true,
        remoteSort: true,
        remoteFilter: true,
        pageSize: 25
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
      dataIndex: 'name',
      header: 'ID',
      width:300,
      filter: {
        type: 'string'
      },
      editor: 'textfield'
    },
    {
      dataIndex: 'mgi_strain_accession_id',
      header: 'MGI Accession Id',
      width:300,
      filter: {
        type: 'string'
      },
      editor: 'textfield'
    },
    {
      dataIndex: 'mgi_strain_name',
      header: 'MGI Strain Name',
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

          if(confirm("Remove strain?"))
            grid.getStore().removeAt(rowIndex)

        }
      }]
    }
    ]
});
