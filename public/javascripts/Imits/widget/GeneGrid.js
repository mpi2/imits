// Helper functions for cell templates - see in the grid below...
function splitResultString(mi_string) {
    var mis = [];
    var pattern = /^\[(.+)\:(.+)\:(\d+)\]$/;
    Ext.Array.each(mi_string.split('<br/>'), function(mi) {
        var match = pattern.exec(mi);
        mis.push({
            consortium: match[1],
            production_centre: match[2],
            count: match[3]
        });
    });
    return mis;
}

function printMiPlanString(mi_plan) {
    var str = '[' + mi_plan['consortium'];
    if (!Ext.isEmpty(mi_plan['production_centre'])) {
        str = str + ':' + mi_plan['production_centre'];
    }
    if (!Ext.isEmpty(mi_plan['status_name'])) {
        str = str + ':' + mi_plan['status_name'];
    }
    str = str + ']';
    return str;
}

Ext.define('Imits.widget.GeneGrid', {
    extend: 'Imits.widget.Grid',
    requires: [
    'Imits.model.Gene',
    'Imits.widget.grid.RansackFiltersFeature',
    'Imits.widget.SimpleCombo',
    'Imits.widget.MiPlanEditor',
    'Ext.ux.RowExpander',
    'Ext.selection.CheckboxModel'
    ],
    title: 'Please Select the Genes You Would Like to Register Interest In*',
    iconCls: 'icon-grid',
    columnLines: true,
    store: {
        model: 'Imits.model.Gene',
        autoLoad: true,
        remoteSort: true,
        remoteFilter: true,
        pageSize: 20
    },
    selModel: Ext.create('Ext.selection.CheckboxModel'),
    features: [
    {
        ftype: 'ransack_filters',
        local: false
    }
    ],
    columns: [
    {
        header: 'Gene',
        dataIndex: 'marker_symbol',
        readOnly: true,
        renderer: function(symbol) {
            return Ext.String.format('<a href="http://www.knockoutmouse.org/martsearch/search?query={0}" target="_blank">{0}</a>', symbol);
        }
    },
    {
        header: 'Production History',
        dataIndex: 'production_history_link',
        renderer: function(value, metaData, record) {
            var geneId = record.getId();
            return Ext.String.format('<a href="{0}/gene/{1}/network_graph">Production Graph</a>', window.basePath, geneId);
        },
        sortable: false
    },
    {
        header: '# IKMC Projects',
        dataIndex: 'ikmc_projects_count',
        readOnly: true
    },
    {
        header: '# Clones',
        dataIndex: 'pretty_print_types_of_cells_available',
        readOnly: true,
        sortable: false
    },
    {
        header: 'Non-Assigned Plans',
        dataIndex: 'non_assigned_mi_plans',
        readOnly: true,
        sortable: false,
        width: 250,
        flex: 1,
        xtype: 'templatecolumn',
        tpl: new Ext.XTemplate(
            '<tpl for="non_assigned_mi_plans">',
            '<a class="mi-plan" data-marker_symbol="{parent.marker_symbol}" data-id="{id}" data-string="{[this.prettyPrintMiPlan(values)]}" href="#">{[this.prettyPrintMiPlan(values)]}</a><br/>',
            '</tpl>',
            {
                prettyPrintMiPlan: printMiPlanString
            }
            )
    },
    {
        header: 'Assigned Plans',
        dataIndex: 'assigned_mi_plans',
        readOnly: true,
        sortable: false,
        width: 180,
        flex: 1,
        xtype: 'templatecolumn',
        tpl: new Ext.XTemplate(
            '<tpl for="assigned_mi_plans">',
            '<a class="mi-plan" data-marker_symbol="{parent.marker_symbol}" data-id="{id}" data-string="{[this.prettyPrintMiPlan(values)]}" href="#">{[this.prettyPrintMiPlan(values)]}</a><br/>',
            '</tpl>',
            {
                prettyPrintMiPlan: printMiPlanString
            }
            )
    },
    {
        header: 'Aborted MIs',
        dataIndex: 'pretty_print_aborted_mi_attempts',
        readOnly: true,
        sortable: false,
        width: 180,
        flex: 1,
        xtype: 'templatecolumn',
        tpl: new Ext.XTemplate(
            '<tpl for="this.processedMIs(pretty_print_aborted_mi_attempts)">',
            '<a href="' + window.basePath + '/mi_attempts?q[terms]={parent.marker_symbol}&q[production_centre_name]={production_centre}" target="_blank">[{consortium}:{production_centre}:{count}]</a></br>',
            '</tpl>',
            {
                processedMIs: splitResultString
            }
            )
    },
    {
        header: 'MIs in Progress',
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
    },
    {
        header: 'Genotype Confirmed MIs',
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
    },
    {
      header: 'Phenotype Attempts',
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

    registerInterestHandler: function() {
        var grid = this;
        var geneCounter = 0;
        var selectedGenes = grid.getSelectionModel().selected;
        var failedGenes = [];
        var consortiumName  = grid.consortiumCombo.getSubmitValue();
        var productionCentreName = grid.centreCombo.getSubmitValue();
        var subProjectName = grid.subprojectCombo.getSubmitValue();
        var priorityName = grid.priorityCombo.getSubmitValue();

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
                'marker_symbol': markerSymbol,
                'consortium_name': consortiumName,
                'production_centre_name': productionCentreName,
                'sub_project_name': subProjectName,
                'priority_name': priorityName
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

    initMiPlanEditor: function() {
        var grid = this;
        this.miPlanEditor = Ext.create('Imits.widget.MiPlanEditor', {
            listeners: {
                'hide': {
                    fn: function() {
                        grid.reloadStore();
                        grid.setLoading(false);
                    }
                }
            }
        });

        Ext.get(grid.renderTo).on('click', function(event, target) {
            var id = target.getAttribute('data-id');
            grid.setLoading("Editing gene interest....");
            grid.miPlanEditor.edit(id);
        },
        grid,
        {
            delegate: 'a.mi-plan'
        });
    },

    initComponent: function() {
        var grid = this;
        grid.callParent();

        // Add the bottom (pagination) toolbar
        grid.addDocked(Ext.create('Ext.toolbar.Paging', {
            store: grid.getStore(),
            dock: 'bottom',
            displayInfo: true
        }));

        var isSubProjectHidden = true;
        if(window.CAN_SEE_SUB_PROJECT) {
            isSubProjectHidden = false;
        }

        // Add the top (gene selection) toolbar
        grid.consortiumCombo = grid.createComboBox('consortium', 'Consortium', 65, window.CONSORTIUM_OPTIONS, false, false);
        grid.centreCombo     = grid.createComboBox('production_centre', 'Production Centre', 100, window.CENTRE_OPTIONS, true, false);
        grid.subprojectCombo = grid.createComboBox('sub_project', 'Sub Project', 65, window.SUB_PROJECT_OPTIONS, false, isSubProjectHidden);
        grid.priorityCombo   = grid.createComboBox('priority', 'Priority', 47, window.PRIORITY_OPTIONS, false, false);

        grid.addDocked(Ext.create('Ext.toolbar.Toolbar', {
            dock: 'top',
            items: [
            grid.consortiumCombo,
            grid.centreCombo,
            grid.subprojectCombo,
            grid.priorityCombo,
            '  ',
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

        this.initMiPlanEditor();
    }
});
