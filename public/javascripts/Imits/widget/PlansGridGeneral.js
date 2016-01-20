Ext.define('Imits.widget.PlansGridGeneral', {
    extend: 'Imits.widget.PlansGridCommon',

    // extends the MiPlanColumns in MiPlanGridCommon. These column should be independent from the MiPlanGrid (editable grid). columns common to read only grid and editable grid should be added to MiPlanGridCommon.
    additionalColumns: [
                        {'position': 1 ,
                         'data': { header: 'Show In Form',
                                   dataIndex: 'show_link',
                                   renderer: function(value, metaData, record) {
                                       var id = record.getId();
                                       return Ext.String.format('<a href="{0}/plans/{1}">Show in Form</a>', window.basePath, id);
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