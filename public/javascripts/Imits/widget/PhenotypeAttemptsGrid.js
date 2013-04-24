Ext.define('Imits.widget.PhenotypeAttemptsGrid', {
    extend: 'Imits.widget.PhenotypeAttemptsGridCommon',

    additionalColumns: [{'position' : 1,
                         'data' : {header: 'Edit In Form',
                                   dataIndex: 'edit_link',
                                   renderer: function(value, metaData, record) {
                                       var miId = record.getId();
                                       return Ext.String.format('<a href="{0}/phenotype_attempts/{1}">Edit in Form</a>', window.basePath, miId);
                                   },
                                   sortable: false
                                   }
                        },
                        {'position': 5,
                         'data': {header: 'Distribution Centres',
                                  dataIndex: 'distribution_centres_formatted_display',
                                  readOnly: true,
                                  sortable: false,
                                  width: 225,
                                  renderer: function(value, metaData, record){
                                      var paId = record.getId();
                                      var distribution_centres = record.get('distribution_centres_formatted_display');
                                      if (distribution_centres != '') {
                                          return Ext.String.format('<a href="{0}/phenotype_attempts/{1}#distribution_centres" target="_blank">{2}</a>', window.basePath, paId, distribution_centres);
                                      } else {
                                          return Ext.String.format('{0}', distribution_centres);
                                      }
                                 }
                            }
                      }
    ],

    initComponent: function () {
        var grid = this;
        Ext.Array.each(grid.additionalColumns, function(column) {
                grid.addColumn(column['data'], column['position']);
        });
        grid.callParent();
    },

});