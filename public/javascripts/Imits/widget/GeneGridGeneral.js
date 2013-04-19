// gene grid read only
Ext.define('Imits.widget.GeneGridGeneral', {
    extend: 'Imits.widget.GeneGridCommon',

    // extends the geneColumns in GeneGridCommon. These column should be independent from the GeneGrid (edit grid). columns common to read only grid and editable grid should be added to GeneGridCommon.
    additionalColumns: [
                        {'position': 6,
                         'data': {header: 'Aborted MIs',
                                  dataIndex: 'pretty_print_aborted_mi_attempts',
                                  readOnly: true,
                                  sortable: false,
                                  width: 180,
                                  flex: 1,
                                  xtype: 'templatecolumn',
                                  tpl: new Ext.XTemplate(
                                      '<tpl for="this.processedMIs(pretty_print_aborted_mi_attempts)">',
                                      '<a href="' + window.basePath +  '/open/mi_attempts?q[terms]={parent.marker_symbol}&q[production_centre_name]={production_centre}" target="_blank">[{consortium}:{production_centre}:{count}]</a></br>',
                                      '</tpl>',
                                      {
                                          processedMIs: splitResultString
                                      }
                                     )
                                 }
                        },
                        {'position': 7,
                         'data': {header: 'MIs in Progress',
                                  dataIndex: 'pretty_print_mi_attempts_in_progress',
                                  readOnly: true,
                                  sortable: false,
                                  width: 180,
                                  flex: 1,
                                  xtype: 'templatecolumn',
                                  tpl: new Ext.XTemplate(
                                      '<tpl for="this.processedMIs(pretty_print_mi_attempts_in_progress)">',
                                      '<a href="' + window.basePath + '/open/mi_attempts?q[terms]={parent.marker_symbol}&q[production_centre_name]={production_centre}" target="_blank">[{consortium}:{production_centre}:{count}]</a></br>',
                                      '</tpl>',
                                      {
                                          processedMIs: splitResultString
                                      }
                                      )
                                 }
                        },
                        {'position': 8,
                         'data': {header: 'Genotype Confirmed MIs',
                                 dataIndex: 'pretty_print_mi_attempts_genotype_confirmed',
                                 readOnly: true,
                                 sortable: false,
                                 width: 180,
                                 flex: 1,
                                 xtype: 'templatecolumn',
                                 tpl: new Ext.XTemplate(
                                     '<tpl for="this.processedMIs(pretty_print_mi_attempts_genotype_confirmed)">',
                                     '<a href="' + window.basePath + '/open/mi_attempts?q[terms]={parent.marker_symbol}&q[production_centre_name]={production_centre}" target="_blank">[{consortium}:{production_centre}:{count}]</a></br>',
                                     '</tpl>',
                                     {
                                          processedMIs: splitResultString
                                     }
                                 )
                                }
                        },
                        {'position': 9,
                         'data': {header: 'Phenotype Attempts',
                                  dataIndex: 'pretty_print_phenotype_attempts',
                                  readOnly: true,
                                  sortable: false,
                                  width: 180,
                                  flex: 1,
                                  xtype: 'templatecolumn',
                                  tpl: new Ext.XTemplate(
                                      '<tpl for="this.processedMIs(pretty_print_phenotype_attempts)">',
                                      '<a href="' + window.basePath + '/open/phenotype_attempts?q[terms]={parent.marker_symbol}&q[production_centre_name]={production_centre}" target="_blank">[{consortium}:{production_centre}:{count}]</a></br>',
                                      '</tpl>',
                                      {
                                          processedMIs: splitResultString
                                      }
                                  )
                                 }
                      }
           ],

    initComponent: function() {
        var grid = this;

        // Adds additional columns
        Ext.Array.each(grid.additionalColumns, function(column) {
            grid.addColumn(column['data'], column['position']);
        });
        grid.callParent();
    }
})
