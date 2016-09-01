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
                                 width: 130,
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

    registerInterestHandler: function() {
        var grid                 = this;
        var geneCounter          = 0;
        var selectedGenes        = grid.getSelectionModel().selected;
        var failedGenes          = [];
        var consortiumName       = grid.consortiumCombo.getSubmitValue();
        var productionCentreName = grid.centreCombo.getSubmitValue();
        var subProjectName       = grid.subprojectCombo.getSubmitValue();
        var priorityName         = grid.priorityCombo.getSubmitValue();

        var esCellQc              = grid.escellqccheck.getSubmitValue();
        var esCellMouseProduction = grid.escellmouseproductionCheck.getSubmitValue();
        var crisprMouseProduction = grid.crisprmouseproductionCheck.getSubmitValue();
        var mouseAlleleMod        = grid.mouseallelemodificationCheck.getSubmitValue();
        var phenotype             = grid.phenotypeCheck.getSubmitValue();

        if(selectedGenes.length == 0) {
            alert('You must select some genes to register interest in');
            return;
        }
        if(consortiumName == null) {
            alert('You must select a consortium');
            return;
        }
        if(productionCentreName == null) {
            alert('You must select a production centre');
            return;
        }
        if (esCellQc == null && esCellMouseProduction == null && crisprMouseProduction == null && mouseAlleleMod == null && phenotype == null) {
            alert('You must select your intention(s)');
            return;
        }
        if(priorityName == null && (esCellQc != null || esCellMouseProduction != null)) {
            alert('You must select a priority');
            return;
        }

        if (esCellQc != null) esCellQc = true; 
        if (esCellMouseProduction != null) esCellMouseProduction = true; 
        if (crisprMouseProduction != null) crisprMouseProduction = true; 
        if (mouseAlleleMod != null) mouseAlleleMod = true; 
        if (phenotype != null) phenotype = true; 
        
        grid.setLoading(true);


        selectedGenes.each(function(geneRow) {
            var markerSymbol = geneRow.raw['marker_symbol'];
            var miPlan = Ext.create('Imits.model.Plan', {
                'marker_symbol'                    : markerSymbol,
                'consortium_name'                  : consortiumName,
                'production_centre_name'           : productionCentreName,
                'default_sub_project_name'         : subProjectName,
                'es_cell_qc_intent'                : esCellQc,
                'es_cell_mi_attempt_intent'        : esCellMouseProduction,
                'nuclease_mi_attempt_intent'       : crisprMouseProduction,
                'mouse_allele_modification_intent' : mouseAlleleMod,
                'phenotyping_intent'               : phenotype,
                'priority_name'                    : priorityName
            });
            miPlan.save({
                failure: function() {
                    failedGenes.push(markerSymbol);
                },
                callback: function() {
                    geneCounter++;
                    if( geneCounter == selectedGenes.length ) {
                        if( !Ext.isEmpty(failedGenes) ) {
                            alert('An error occured trying to register interest on the following genes: ' + failedGenes.join(', ') + '. Please try again.');
                        }

                        grid.reloadStore();
                        grid.setLoading(false);
                    }
                }
            });
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

        // Add the top (gene selection) toolbar
        grid.consortiumCombo              = grid.createComboBox('consortium', 'Consortium', 65, window.CONSORTIUM_OPTIONS, false, false);
        grid.centreCombo                  = grid.createComboBox('production_centre', 'Production Centre', 100, window.CENTRE_OPTIONS, true, false);
        grid.subprojectCombo              = grid.createComboBox('sub_project', 'Sub Project', 65, window.SUB_PROJECT_OPTIONS, false, isSubProjectHidden);
        grid.escellqccheck                = grid.createCheckBox('es_cell_qc', 'QC ES Cells', 60, false);
        grid.priorityCombo                = grid.createComboBox('priority', 'Priority', 47, window.PRIORITY_OPTIONS, false, false);
        grid.escellmouseproductionCheck   = grid.createCheckBox('es_cell_mouse_production', 'Produce Mouse via Micro-Injection of ES Cell', 125, false);
        grid.crisprmouseproductionCheck   = grid.createCheckBox('crispr_mouse_production', 'Produce Mouse via Micro-Injection of Nuclease', 125, false);
        grid.mouseallelemodificationCheck = grid.createCheckBox('mouse_allele_modification', 'Modify Mouse Allele', 85, false);
        grid.phenotypeCheck               = grid.createCheckBox('phenotype', 'Phenotype', 65, false);


        grid.addDocked(Ext.create('Ext.toolbar.Toolbar', {
            dock: 'top',
            items: [
            'Use check boxes below to assign genes to ...',
            grid.consortiumCombo,
            grid.centreCombo,
            grid.subprojectCombo
            ]
        }));

        grid.addDocked(Ext.create('Ext.toolbar.Toolbar', {
            dock: 'top',
            items: [
            '',
            '',
            '',
            '',
            '',
            '',
            '',
            '',
            '',
            'With the intention(s) to ...',
            grid.escellqccheck,
            grid.escellmouseproductionCheck,
            grid.crisprmouseproductionCheck,
            grid.mouseallelemodificationCheck,
            grid.phenotypeCheck,
            grid.priorityCombo,
            '',
            {
                id: 'register_interest_button',
                text: 'Assign Genes',
                cls:'x-btn-text-icon',
                iconCls: 'icon-add',
                grid: grid,
                handler: function() {
                    grid.registerInterestHandler();
                }
            }
            ]
       }));
    }
});
