Ext.define('Imits.widget.MiPlansGrid', {
    extend: 'Imits.widget.MiPlansGridCommon',

    // extends the MiPlanColumns in MiPlanGridCommon. These column should be independent from the MiPlanGridGeneral (read only grid). columns common to read only grid and editable grid should be added to MiPlanGridCommon.
    additionalColumns: [{'position': 1 ,
                         'data': { header: 'Edit In Form',
                                   dataIndex: 'edit_link',
                                   renderer: function(value, metaData, record) {
                                       var id = record.getId();
                                       return Ext.String.format('<a href="{0}/mi_plans/{1}">Edit in Form</a>', window.basePath, id);
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

        grid.miPlanEditor = Ext.create('Imits.widget.MiPlanEditor', {
            listeners: {
                'hide': {
                    fn: function () {
                        grid.reloadStore();
                        grid.setLoading(false);
                    }
                }
            }
        });

        grid.addListener('itemclick', function (theView, record, item, index, event, eventOptions) {
            var target = Ext.get(event.getTarget());
            if (target.dom.nodeName.toLowerCase() !== 'a') {
                var id = record.data['id'];
                grid.setLoading("Editing plan....");
                grid.miPlanEditor.edit(id);
            }
        });
        this.callParent();
    }
})