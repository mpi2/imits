// gene grid with edit functionality
Ext.define('Imits.widget.GeneGrid', {
    extend: 'Imits.widget.GeneGridCommon',
    requires: [
    'Imits.model.Gene',
    'Imits.widget.grid.RansackFiltersFeature',
    'Imits.widget.SimpleCombo',
    'Ext.ux.RowExpander',
    'Imits.widget.SimpleCheckbox'
    ],
    selModel: Ext.create('Ext.selection.CheckboxModel'),
    features: [
    {
        ftype: 'ransack_filters',
        local: false
    }
    ],
    // extends the geneColumns in GeneGridCommon. These column should be independent from the GeneGridCommon (read only grid). columns common to read only grid and editable grid should be added to GeneGridCommon.
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
                                        '<a href="' + window.basePath + '/mi_plans/{[values["id"]]}" target="_blank">{[this.prettyPrintMiPlan(values)]}</a></br>',
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
                                      '<a href="' + window.basePath + '/mi_plans/{[values["id"]]}" target="_blank">{[this.prettyPrintMiPlan(values)]}</a></br>',
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
                                      '<a href="' + window.basePath +  '/mi_attempts?q[terms]={parent.marker_symbol}&q[production_centre_name]={production_centre}" target="_blank">[{consortium}:{production_centre}:{count}]</a></br>',
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
                                      '<a href="' + window.basePath + '/mi_attempts?q[terms]={parent.marker_symbol}&q[production_centre_name]={production_centre}" target="_blank">[{consortium}:{production_centre}:{count}]</a></br>',
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
                                     '<a href="' + window.basePath + '/mi_attempts?q[terms]={parent.marker_symbol}&q[production_centre_name]={production_centre}" target="_blank">[{consortium}:{production_centre}:{count}]</a></br>',
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
                                      '<a href="' + window.basePath + '/phenotype_attempts?q[terms]={parent.marker_symbol}&q[production_centre_name]={production_centre}" target="_blank">[{consortium}:{production_centre}:{count}]</a></br>',
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
                                     return Ext.String.format('<a href="{0}/genes/{1}/network_graph">Production Graph</a>', window.basePath, geneId);
                                 },
                                 sortable: false
                                 }
                        }

    ],

           /** @private **/
    createComboBox: function(id, label, labelWidth, store, includeBlank, isHidden) {
        if(includeBlank) {
            store = Ext.Array.merge([null], store);
        }
        return Ext.create('Imits.widget.SimpleCombo', {
            id: id + 'Combobox',
            store: store,
            fieldLabel: label,
            labelAlign: 'right',
            labelWidth: labelWidth,
            storeOptionsAreSpecial: true,
            hidden: isHidden
        });
    },

    createCheckBox: function(id, label, labelWidth, isHidden) {
        return Ext.create('Imits.widget.SimpleCheckbox', {
            id: id + 'Checkbox',
            fieldLabel: label,
            labelAlign: 'right',
            labelWidth: labelWidth,
            hidden: isHidden
        });
    },


    initComponent: function() {
        var grid = this;

        // Adds additional columns
        Ext.Array.each(grid.additionalColumns, function(column) {
            grid.addColumn(column['data'], column['position']);
        });
        grid.callParent();

        var isSubProjectHidden = true;
        if(window.CAN_SEE_SUB_PROJECT) {
            isSubProjectHidden = false;
        }
    }
});
