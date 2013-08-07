// gene grid read only
Ext.define('Imits.widget.GeneGridGeneral', {
    extend: 'Imits.widget.GeneGridCommon',

    // extends the geneColumns in GeneGridCommon. These column should be independent from the GeneGrid (edit grid). columns common to read only grid and editable grid should be added to GeneGridCommon.
    additionalColumns: [
                         {'position': 4,
                          'data': { header: 'Non-Assigned Plans',
                                    dataIndex: 'non_assigned_mi_plans',
                                    readOnly: true,
                                    sortable: false,
                                    width: 250,
                                    flex: 1,
                                    xtype: 'templatecolumn',
                                    tpl: new Ext.XTemplate(
                                        '<tpl for="non_assigned_mi_plans">',
                                        '<a href="' + window.basePath + '/open/mi_plans/{[values["id"]]}">{[this.prettyPrintMiPlan(values)]}</a></br>',
                                        '</tpl>',
                                        {
                                            prettyPrintMiPlan: printMiPlanString
                                        }
                                        )
                                   }
                         },
                         {'position': 5,
                         'data': {header: 'Assigned Plans',
                                  dataIndex: 'assigned_mi_plans',
                                  readOnly: true,
                                  sortable: false,
                                  width: 180,
                                  flex: 1,
                                  xtype: 'templatecolumn',
                                  tpl: new Ext.XTemplate(
                                      '<tpl for="assigned_mi_plans">',
                                      '<a href="' + window.basePath + '/open/mi_plans/{[values["id"]]}">{[this.prettyPrintMiPlan(values)]}</a></br>',
                                      '</tpl>',
                                      {
                                          prettyPrintMiPlan: printMiPlanString
                                      }
                                      )
                                  }
                        },
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
                        },
                        {'position': 1,
                         'data': {header: 'Production History',
                                 dataIndex: 'production_history_link',
                                 renderer: function (value, metaData, record) {
                                     var geneId = record.getId();
                                     return Ext.String.format('<a href="{0}/open/genes/{1}/network_graph">Production Graph</a>', window.basePath, geneId);
                                 },
                                 sortable: false
                                 }
                        },
                        {'position' : 2,
                           'data' : {header: 'Production Summary',
                                     dataIndex: 'production_summary',
                                     width: 125,
                                     renderer: function(value, metaData, record) {
                                         var mgi_accession_id = record.get('mgi_accession_id');
                                         if (mgi_accession_id != '') {
                                           return Ext.String.format('<a href="https://www.mousephenotype.org/data/genes/{0}">Summary</a>', mgi_accession_id);
                                         } else {
                                           return Ext.String.format('{0}', Summary);
                                         }
                                     },
                                     sortable: false
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
