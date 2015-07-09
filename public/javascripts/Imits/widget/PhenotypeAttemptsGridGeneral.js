Ext.define('Imits.widget.PhenotypeAttemptsGridGeneral', {
    extend: 'Imits.widget.PhenotypeAttemptsGridCommon',

    additionalColumns: [{'position' : 1,
                         'data' : {header: 'Show In Form',
                                   dataIndex: 'show_link',
                                   renderer: function(value, metaData, record) {
                                       var miId = record.getId();
                                       return Ext.String.format('<a href="{0}/open/phenotype_attempts/{1}">Show in Form</a>', window.basePath, miId);
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
                                          return Ext.String.format('<a href="{0}/open/phenotype_attempts/{1}#distribution_centres" target="_blank">{2}</a>', window.basePath, paId, distribution_centres);
                                      } else {
                                          return Ext.String.format('{0}', distribution_centres);
                                      }
                                 }
                            }
                      },
                      {'position' : 2,
                         'data' : {header: 'Phenotyping Summary',
                                   dataIndex: 'phenotyping_summary',
                                   width: 125,
                                   renderer: function(value, metaData, record) {
                                       var mgi_accession_id = record.get('mgi_accession_id');
                                       if (mgi_accession_id != '') {
                                         return Ext.String.format('<a href="https://www.mousephenotype.org/data/genes/{0}">View in IMPC Website</a>', mgi_accession_id);
                                       } else {
                                         return Ext.String.format('{0}', '');
                                       }
                                   },
                                   sortable: false
                                   }
                        }
    ],

    initComponent: function () {
        var grid = this;
        Ext.Array.each(grid.additionalColumns, function(column) {
                grid.addColumn(column['data'], column['position']);
        });
        grid.callParent();
    }

});
