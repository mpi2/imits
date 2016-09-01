Ext.define('Imits.widget.PlansGrid', {
    extend: 'Imits.widget.PlansGridCommon',

    // allows grid to be edited.
    plugins: [
    Ext.create('Ext.grid.plugin.RowEditing', {
        autoCancel: false,
        clicksToEdit: 1
    })
    ],
    
    downloadData : function() {
        var grid                 = this;
    },

     //extends the MiPlanColumns in MiPlanGridCommon. These column should be independent from the MiPlanGridGeneral (read only grid). columns common to read only grid and editable grid should be added to MiPlanGridCommon.
    additionalColumns: [
                        {'position': 1 ,
                         'data': { header: 'Edit In Form',
                                   dataIndex: 'edit_link',
                                   renderer: function(value, metaData, record) {
                                       var id = record.getId();
                                       return Ext.String.format('<a href="{0}/plans/{1}">Edit in Form</a>', window.basePath, id);
                                   },
                                   sortable: false
                                  }
                         }
    ],

    initComponent: function() {
        grid = this;
        // Adds additional columns
        Ext.Array.each(grid.additionalColumns, function(column) {
            grid.addColumn(column['data'], column['position']);
        });
        this.callParent();
    }
})