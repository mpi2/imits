// Helper functions for cell templates - see in the grid below...
function splitMiString(mi_string) {
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
    title: 'Please Select the Genes You Would Like to Register Interest In',
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
        header: 'Non-Assigned MIs',
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
        header: 'Assigned MIs',
        dataIndex: 'assigned_mi_plans',
        readOnly: true,
        sortable: false,
        width: 200,
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
        width: 200,
        flex: 1,
        xtype: 'templatecolumn',
        tpl: new Ext.XTemplate(
            '<tpl for="this.processedMIs(pretty_print_aborted_mi_attempts)">',
            '<a href="' + window.basePath + '/mi_attempts?q[terms]={parent.marker_symbol}&q[production_centre_name]={production_centre}" target="_blank">[{consortium}:{production_centre}:{count}]</a></br>',
            '</tpl>',
            {
                processedMIs: splitMiString
            }
            )
    },
    {
        header: 'MIs in Progress',
        dataIndex: 'pretty_print_mi_attempts_in_progress',
        readOnly: true,
        sortable: false,
        width: 200,
        flex: 1,
        xtype: 'templatecolumn',
        tpl: new Ext.XTemplate(
            '<tpl for="this.processedMIs(pretty_print_mi_attempts_in_progress)">',
            '<a href="' + window.basePath + '/mi_attempts?q[terms]={parent.marker_symbol}&q[production_centre_name]={production_centre}" target="_blank">[{consortium}:{production_centre}:{count}]</a></br>',
            '</tpl>',
            {
                processedMIs: splitMiString
            }
            )
    },
    {
        header: 'GLT Mice',
        dataIndex: 'pretty_print_mi_attempts_genotype_confirmed',
        readOnly: true,
        sortable: false,
        width: 200,
        flex: 1,
        xtype: 'templatecolumn',
        tpl: new Ext.XTemplate(
            '<tpl for="this.processedMIs(pretty_print_mi_attempts_genotype_confirmed)">',
            '<a href="' + window.basePath + '/mi_attempts?q[terms]={parent.marker_symbol}&q[production_centre_name]={production_centre}" target="_blank">[{consortium}:{production_centre}:{count}]</a></br>',
            '</tpl>',
            {
                processedMIs: splitMiString
            }
            )
    }
    ],

    /** @private **/
    createComboBox: function(id, label, labelWidth, store, includeBlank) {
        if(includeBlank) {
            store = Ext.Array.merge([null], store);
        }
        return Ext.create('Imits.widget.SimpleCombo', {
            id: id + 'Combobox',
            store: store,
            fieldLabel: label,
            labelAlign: 'right',
            labelWidth: labelWidth,
            storeOptionsAreSpecial: true
        });
    },

    registerInterestHandler: function() {
        var grid = this;
        var geneCounter = 0;
        var selectedGenes = grid.getSelectionModel().selected;
        var failedGenes = [];
        var consortiumName  = grid.consortiumCombo.getSubmitValue();
        var productionCentreName = grid.centreCombo.getSubmitValue();
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
            grid.setLoading("Editing expression of micro-injection interest....");
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

        // Add the top (gene selection) toolbar
        grid.consortiumCombo = grid.createComboBox('consortium', 'Consortium', 65, window.CONSORTIUM_COMBO_OPTS);
        grid.centreCombo     = grid.createComboBox('production_centre', 'Production Centre', 100, window.CENTRE_COMBO_OPTS, true);
        grid.priorityCombo   = grid.createComboBox('priority', 'Priority', 47, window.PRIORITY_COMBO_OPTS);

        grid.addDocked(Ext.create('Ext.toolbar.Toolbar', {
            dock: 'top',
            items: [
            grid.consortiumCombo,
            grid.centreCombo,
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
