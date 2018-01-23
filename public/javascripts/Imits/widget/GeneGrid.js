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
                        {'position': 1 ,
                         'data': {header: 'Tree',
                                  readOnly: true,
                                  renderer: function (value, metaData, record) {
                                      var mgiId = record.get('mgi_accession_id');
                                      var iconURL = '<img src="' + window.basePath + '/images/icons/application_side_tree.png" alt="Blah"/>';
                                      return Ext.String.format('<a href="{0}/genes/{1}/relationship_tree">{2}</a>', window.basePath, mgiId, iconURL);
                                  },
                                  width: 40,
                                  sortable: false
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

    registerInterestHandler: function() {
        var grid                 = this;
        var geneCounter          = 0;
        var selectedGenes        = grid.getSelectionModel().selected;
        var failedGenes          = [];
        var consortiumName       = grid.consortiumCombo.getSubmitValue();
        var productionCentreName = grid.centreCombo.getSubmitValue();
        var subProjectName       = grid.subprojectCombo.getSubmitValue();
        var PhenotypeOnly        = grid.phenotypeonlyCheck.getSubmitValue() || false;
        var esCellQcOnly         = grid.escellqconlyCheck.getSubmitValue() || false;
        var Crispr               = grid.crisprCheck.getSubmitValue() || false;
        var priorityName         = grid.priorityCombo.getSubmitValue();
        var isBespokeAllele      = grid.isbespokealleleCheck.getSubmitValue() || false;
        var isConditionalAllele  = grid.isconditionalalleleCheck.getSubmitValue() || false;
        var isDeletionAllele     = grid.isdeletionalleleCheck.getSubmitValue() || false;
        var isCreKnockInAllele   = grid.iscreknockinalleleCheck.getSubmitValue() || false;
        var isCreBacAllele       = grid.iscrebacalleleCheck.getSubmitValue() || false;
        var conditionalTm1c      = grid.conditionaltm1cCheck.getSubmitValue() || false;
        var pointMutation        = grid.pointmutationCheck.getSubmitValue() || false;
        var conditionalPointMutation = grid.conditionalpointmutationCheck.getSubmitValue() || false;

        if(selectedGenes.length == 0) {
            alert('You must select some genes to register interest in');
            return;
        }
        if(consortiumName == null) {
            alert('You must select a consortium');
            return;
        }
        if(priorityName == null) {
            alert('You must selct a priority');
            return;
        }

        grid.setLoading(true);

        selectedGenes.each(function(geneRow) {
            var markerSymbol = geneRow.raw['marker_symbol'];
            var miPlan = Ext.create('Imits.model.MiPlan', {
                'marker_symbol'          : markerSymbol,
                'consortium_name'        : consortiumName,
                'production_centre_name' : productionCentreName,
                'sub_project_name'       : subProjectName,
                'phenotype_only'         : PhenotypeOnly,
                'es_cell_qc_only'        : esCellQcOnly,
                'mutagenesis_via_crispr_cas9' : Crispr,
                'priority_name'          : priorityName,
                'is_bespoke_allele'      : isBespokeAllele,
                'is_conditional_allele'  : isConditionalAllele,
                'is_deletion_allele'     : isDeletionAllele,
                'is_cre_knock_in_allele' : isCreKnockInAllele,
                'is_cre_bac_allele'      : isCreBacAllele,
                'conditional_tm1c'       : conditionalTm1c,
                'point_mutation'         : pointMutation,
                'conditional_point_mutation' : conditionalPointMutation
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
        grid.consortiumCombo  = grid.createComboBox('consortium', 'Consortium', 65, window.CONSORTIUM_OPTIONS, false, false);
        grid.centreCombo      = grid.createComboBox('production_centre', 'Production Centre', 100, window.CENTRE_OPTIONS, true, false);
        grid.subprojectCombo  = grid.createComboBox('sub_project', 'Sub Project', 65, window.SUB_PROJECT_OPTIONS, false, isSubProjectHidden);
        grid.priorityCombo    = grid.createComboBox('priority', 'Priority', 47, window.PRIORITY_OPTIONS, false, false);
        grid.phenotypeonlyCheck     = grid.createCheckBox('phenotype_only', 'Phenotype Only', 85, false);
        grid.escellqconlyCheck     = grid.createCheckBox('es_cell_qc_only', 'ES Cell QC Only', 85, false);
        grid.crisprCheck              = grid.createCheckBox('mutagenesis_via_crispr_cas9', 'Mutagenesis Via Crispr/Cas9?', 85, false);
        grid.isbespokealleleCheck     = grid.createCheckBox('is_bespoke_allele', 'Bespoke', 52, false);
        grid.isconditionalalleleCheck = grid.createCheckBox('is_conditional_allele', 'Knockout First Tm1a', 120, false);
        grid.isdeletionalleleCheck    = grid.createCheckBox('is_deletion_allele', 'Deletion', 57, false);
        grid.iscreknockinalleleCheck  = grid.createCheckBox('is_cre_knock_in_allele', 'Cre Knock In', 80, false);
        grid.iscrebacalleleCheck      = grid.createCheckBox('is_cre_bac_allele', 'Cre Bac', 55, false);
        grid.conditionaltm1cCheck      = grid.createCheckBox('conditional_tm1c', 'Conditional tm1c', 100, false);
        grid.pointmutationCheck      = grid.createCheckBox('point_mutation', 'Point Mutation', 80, false);
        grid.conditionalpointmutationCheck      = grid.createCheckBox('conditional_point_mutation', 'Conditional Point Mutation', 135, false);

        grid.addDocked(Ext.create('Ext.toolbar.Toolbar', {
            dock: 'top',
            items: [
            grid.consortiumCombo,
            grid.centreCombo,
            grid.subprojectCombo,
            grid.priorityCombo,
            grid.crisprCheck,
            grid.phenotypeonlyCheck,
            grid.escellqconlyCheck
            ]
        }));

        grid.addDocked(Ext.create('Ext.toolbar.Toolbar', {
            dock: 'top',
            items: [
            grid.isbespokealleleCheck,
            grid.isconditionalalleleCheck,
            grid.conditionaltm1cCheck,
            grid.isdeletionalleleCheck,
            grid.iscreknockinalleleCheck,
            grid.iscrebacalleleCheck,
            grid.pointmutationCheck,
            grid.conditionalpointmutationCheck,
            '',
            '',
            {
                id: 'register_interest_button',
                text: 'Register Interest',
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
