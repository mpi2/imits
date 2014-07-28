function splitString(prettyPrintDistributionCentres) {
    var distributionCentres = [];
    Ext.Array.each(prettyPrintDistributionCentres.split(', '), function(dc) {
        distributionCentres.push({
            distributionCentre: dc
        });
    });

    return distributionCentres;
}

// traps the selection of new column sets via the grid menu buttons
function onItemClick(item){
    function intensiveOperation() {
        var columnsToShow = grid.views[item.text];

        if (typeof columnsToShow == 'undefined') {
            alert('Unrecognised column filter: ' + item.text);
        } else {
            // filter rows on cas9 flag
            switch(item.text) {
                case 'Everything':
                case 'Summary':
                    // filter cas9 inactivated
                    grid.deactivateCrisprFilter();
                    break;
                case 'ES Cell Transfer Details':
                case 'ES Cell Litter Details':
                case 'ES Cell Chimera Mating Details':
                case 'ES Cell QC Details':
                    // filter cas9 off
                    grid.activateCrisprFilterWithValue(false);
                    break;
                case 'Crispr Transfer Details':
                case 'Crispr Founder Details':
                case 'Crispr F1 Details':
                case 'Crispr QC Details':
                    // filter cas9 on
                    grid.activateCrisprFilterWithValue(true);
                    break;
                default:
                    break;
            };

            // select which columns to show
            var columnsToShowHash = {};
            Ext.each(columnsToShow, function(columnToShow) {
                columnsToShowHash[columnToShow] = true;
            });

            // setVisible method is slow, so suspend layouts then do all the setVisibles then resume
            Ext.suspendLayouts();
            Ext.each(grid.columns, function(column) {
                if(column.dataIndex in columnsToShowHash) {
                    column.setVisible(true);
                } else {
                    column.setVisible(false);
                }
            });

            // move columns arround if needed
            switch(item.text) {
                case 'ES Cell Transfer Details':
                case 'ES Cell Litter Details':
                case 'ES Cell Chimera Mating Details':
                case 'ES Cell QC Details':
                    grid.moveColumnToIndex("es_cell_name",6);
                    grid.moveColumnToIndex("es_cell_allele_symbol",8);
                    break;
                default:
                    break;
            };

            Ext.resumeLayouts(true);

            grid.setTitle('Micro-Injection Attempts - ' + item.text);
        }

        mask.hide();
        Ext.getBody().removeCls('wait');
    }

    var mask = new Ext.LoadMask(grid.getEl(),
    {
        msg: 'Please wait&hellip;',
        removeMask: true
    });

    Ext.getBody().addCls('wait');
    mask.show();
    setTimeout(intensiveOperation, 100);
}

Ext.define('Imits.widget.MiGridCommon', {
    extend: 'Imits.widget.Grid',

    requires: [
    'Imits.model.MiAttempt',
    'Imits.widget.SimpleNumberField',
    'Imits.widget.SimpleCombo',
    'Imits.widget.QCCombo',
    'Imits.widget.grid.BoolGridColumn',
    'Imits.widget.grid.MiAttemptRansackFiltersFeature',
    'Imits.widget.grid.SimpleDateColumn',
    'Imits.Util',
    'Ext.util.HashMap'
    ],

    title: 'Micro-Injection Attempts - Everything',
    store: {
        model: 'Imits.model.MiAttempt',
        autoLoad: true,
        autoSync: true,
        remoteSort: true,
        pageSize: 20
    },

    selType: 'rowmodel',

    features: [
    {
        ftype: 'mi_attempt_ransack_filters',
        local: false
    }
    ],

    /** @private */
    addColumnsToGroupedColumns: function(group, relative_position, new_column) {
      this.groupedColumns[group].splice(relative_position, 0, new_column)
    },

    generateColumns: function(config) {
        var columns = [];

        Ext.Object.each(this.groupedColumns, function(viewName, viewColumns) {
            Ext.Array.each(viewColumns, function(column) {
                var existing;
                Ext.each(columns, function(i) {
                    if(i.dataIndex == column.dataIndex && i.header == column.header) {
                        existing = i;
                    }
                });
                if(!existing) {
                    column.tdCls = 'column-' + column.dataIndex;
                    columns.push(column);
                }
            });
        });

        config.columns = columns;
    },

    /** @private */
    generateViews: function() {
        var views = {};

        var commonColumns       = Ext.pluck(this.groupedColumns.common, 'dataIndex');
        var esCellCommonColumns = Ext.pluck(this.groupedColumns.es_cell_common, 'dataIndex');
        var crisprCommonColumns = Ext.pluck(this.groupedColumns.crispr_common, 'dataIndex');

        var everythingView      = Ext.Array.merge(commonColumns, esCellCommonColumns, crisprCommonColumns, []);

        // First generate the groups from the groupedColumns
        Ext.Object.each(this.groupedColumns, function(viewName, viewColumnConfigs) {
            // switch what columns are displayed based on view name
            switch(viewName) {
                case 'common':
                case 'es_cell_common':
                case 'crispr_common':
                case 'none':
                    return;
                case 'ES Cell Transfer Details':
                case 'ES Cell Litter Details':
                case 'ES Cell Chimera Mating Details':
                case 'ES Cell QC Details':
                    var viewColumns = Ext.pluck(viewColumnConfigs, 'dataIndex');
                    views[viewName] = Ext.Array.merge(commonColumns, esCellCommonColumns, viewColumns);
                    everythingView = Ext.Array.merge(everythingView, viewColumns);
                    break;
                case 'Crispr Transfer Details':
                case 'Crispr Founder Details':
                case 'Crispr F1 Details':
                case 'Crispr QC Details':
                    var viewColumns = Ext.pluck(viewColumnConfigs, 'dataIndex');
                    views[viewName] = Ext.Array.merge(commonColumns, crisprCommonColumns, viewColumns);
                    everythingView = Ext.Array.merge(everythingView, viewColumns);
                    break;
                default:
                    return;
            }
        });

        views['Everything'] = everythingView;

        var grid = this;
        Ext.Object.each(this.additionalViewColumns, function(viewName) {
            views[viewName] = Ext.Array.merge(commonColumns, esCellCommonColumns, crisprCommonColumns, grid.additionalViewColumns[viewName]);
        });
        this.views = views;
    },

    constructor: function(config) {
        if(config == undefined) {
            config = {};
        }
        this.generateColumns(config);
        this.generateViews();
        this.callParent([config]);
    },

    switchViewMenuButtonConfig: function(text, menuContent) {
        var grid = this;
        return {
            text: text,
            enableToggle: true,
            allowDepress: false,
            toggleGroup: 'mi_grid_view_config',
            minWidth: 100,
            pressed: false,
            menu: menuContent,
            listeners: {
                'toggle': function(button, pressed) {
                    if(!pressed) {
                        return;
                    }
                }
            }
        };
    },

    initComponent: function() {
        var self = this;

        self.callParent();

        self.addDocked(Ext.create('Ext.toolbar.Paging', {
            store: self.getStore(),
            dock: 'bottom',
            displayInfo: true
        }));

        var everythingMenuConfig = [
            { text:'Summary', handler: onItemClick },
            { text:'Everything', handler: onItemClick }
        ];

        var esCellsMenuConfig = [
            { text:'ES Cell Transfer Details', handler: onItemClick },
            { text:'ES Cell Litter Details', handler: onItemClick },
            { text:'ES Cell Chimera Mating Details', handler: onItemClick },
            { text:'ES Cell QC Details', handler: onItemClick }
        ];

        var crisprsMenuConfig = [
            { text:'Crispr Transfer Details', handler: onItemClick },
            { text:'Crispr Founder Details', handler: onItemClick }//,
            // { text:'Crispr F1 Details', handler: onItemClick },
            // { text:'Crispr QC Details', handler: onItemClick }
        ];

        self.menuBtnEverything = self.switchViewMenuButtonConfig( 'Everything', everythingMenuConfig );
        self.menuBtnESCells    = self.switchViewMenuButtonConfig( 'ES Cells', esCellsMenuConfig );
        self.menuBtnCrisprs    = self.switchViewMenuButtonConfig( 'Crisprs', crisprsMenuConfig );

        self.addDocked(Ext.create('Ext.container.ButtonGroup', {
            layout: 'hbox',
            dock: 'top',
            items: [
                self.menuBtnEverything,
                self.menuBtnESCells,
                self.menuBtnCrisprs
            ]
        }));

        self.addListener('afterrender', function () {
            self.filters.createFilters();
        });
    },

    activateCrisprFilterWithValue: function(value) {
        var self = this;

        var iA = self.filters.getFilter('mi_plan_mutagenesis_via_crispr_cas9').isActivatable();
        self.filters.getFilter('mi_plan_mutagenesis_via_crispr_cas9').setValue(value);
        self.filters.getFilter('mi_plan_mutagenesis_via_crispr_cas9').setActive(true);
        if(iA === true) {
            self.getStore().reload();
        }
    },

    deactivateCrisprFilter: function() {
        var self = this;

        var iA = self.filters.getFilter('mi_plan_mutagenesis_via_crispr_cas9').isActivatable();
        self.filters.getFilter('mi_plan_mutagenesis_via_crispr_cas9').setActive(false);
        if(iA === true) {
            self.getStore().reload();
        }
    },

    findColumnIndex: function(columns, dataIndex) {
        var index;
        for (index = 0; index < columns.length; ++index) {
            console.log("index " + index + " = " + columns[index].dataIndex);
            if (columns[index].dataIndex == dataIndex) {
                break;
            }
        }
        return index == columns.length ? -1 : index;
    },

    moveColumnToIndex: function(columnName, newColumnIndex) {
        var self = this;
        var col_index = grid.findColumnIndex(self.headerCt.getGridColumns(), columnName);
        console.log(columnName + " current index = " + col_index);
        if (col_index != -1 && col_index != newColumnIndex) {
            self.headerCt.move(col_index, newColumnIndex);
        }
    },

    // BEGIN COLUMN DEFINITION

    groupedColumns: {
        'none': [
        {
            dataIndex: 'id',
            header: 'ID',
            readOnly: true,
            hidden: (Imits.Util.extractValueIfExistent(window.MI_ATTEMPT_SEARCH_PARAMS, 'mi_attempt_id') ? false : true),
            filter: {
                type: 'string',
                value: Imits.Util.extractValueIfExistent(window.MI_ATTEMPT_SEARCH_PARAMS, 'mi_attempt_id')
            }
        }
        ],

        'common': [
        {
            header: 'Active Phenotype',
            dataIndex: 'phenotype_attempts_count',
            readOnly: true,
            sortable: false,
            width: 115,
            renderer: function(value, metaData, record){
                var miId = record.getId();
                var phenotypeCount = record.get('phenotype_attempts_count');
                var geneSymbol = record.get('marker_symbol');
                var productionCentre = record.get('production_centre_name');
                if (phenotypeCount != 0) {
                    return Ext.String.format('<a href="{0}/phenotype_attempts?q[terms]={1}&q[production_centre_name]={2}">{3}</a>', window.basePath, geneSymbol, productionCentre, phenotypeCount);
                } else {
                    return Ext.String.format('{0}', phenotypeCount);
                }
            }
        },
        {
            dataIndex: 'consortium_name',
            header: 'Consortium',
            readOnly: true,
            width: 115,
            filter: {
                type: 'list',
                options: window.MI_ATTEMPT_CONSORTIUM_OPTIONS,
                value: Imits.Util.extractValueIfExistent(window.MI_ATTEMPT_SEARCH_PARAMS, 'consortium_name')
            },
            sortable: false
        },
        {
            dataIndex: 'production_centre_name',
            header: 'Production Centre',
            readOnly: true,
            filter: {
                type: 'list',
                options: window.MI_ATTEMPT_CENTRE_OPTIONS,
                value: Imits.Util.extractValueIfExistent(window.MI_ATTEMPT_SEARCH_PARAMS, 'production_centre_name')
            },
            sortable: false
        },
        {
            dataIndex: 'marker_symbol',
            header: 'Marker Symbol',
            width: 105,
            readOnly: true,
            sortable: false,
        },
        {
            xtype: 'simpledatecolumn',
            dataIndex: 'mi_date',
            header: 'MI Date'
        },
        {
            dataIndex: 'status_name',
            header: 'Status',
            width: 150,
            readOnly: true,
            sortable: false,
            filter: {
                type: 'list',
                options: window.MI_ATTEMPT_STATUS_OPTIONS,
                value: Imits.Util.extractValueIfExistent(window.MI_ATTEMPT_SEARCH_PARAMS, 'status_name')
            }
        },
        {
            dataIndex: 'colony_name',
            header: 'Colony Name',
            editor: 'textfield',
            filter: {
                type: 'string',
                value: Imits.Util.extractValueIfExistent(window.MI_ATTEMPT_SEARCH_PARAMS, 'colony_name')
            }
        }
        ],

        'es_cell_common': [
        {
            dataIndex: 'es_cell_name',
            header: 'ES Cell',
            readOnly: true,
            sortable: false,
            filter: {
                type: 'string',
                value: Imits.Util.extractValueIfExistent(window.MI_ATTEMPT_SEARCH_PARAMS, 'es_cell_name')
            }
        },
        {
            dataIndex: 'es_cell_allele_symbol',
            header: 'Allele symbol',
            readOnly: true,
            sortable: false
        }
        ],

        'crispr_common': [
         {
            dataIndex: 'mi_plan_mutagenesis_via_crispr_cas9',
            header: 'CrispR Cas9',
            readOnly: true,
            sortable: false,
            filter: {
                type: 'boolean'
            }
        }
        ],

        'ES Cell Transfer Details': [
        {
            dataIndex: 'blast_strain_name',
            header: 'Blast Strain',
            sortable: false,
            renderer: 'safeTextRenderer',
            width: 200,
            editor: {
                xtype: 'simplecombo',
                store: Ext.Array.merge([''], window.MI_ATTEMPT_STRAIN_OPTIONS),
                storeOptionsAreSpecial: true,
                listConfig: {
                    minWidth: 200
                }
            }
        },
        {
            dataIndex: 'total_blasts_injected',
            header: 'Total Blasts Injected',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'total_transferred',
            header: 'Total Transferred',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_surrogates_receiving',
            header: '# Surrogates Receiving',
            editor: 'simplenumberfield'
        }
        ],

        'ES Cell Litter Details': [
        {
            dataIndex: 'total_pups_born',
            header: 'Total Pups Born',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'total_female_chimeras',
            header: 'Total Female Chimeras',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'total_male_chimeras',
            header: 'Total Male Chimeras',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'total_chimeras',
            header: 'Total Chimeras',
            readOnly: true
        },
        {
            dataIndex: 'number_of_males_with_100_percent_chimerism',
            header: '100% Male Chimerism Levels',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_males_with_80_to_99_percent_chimerism',
            header: '99-80% Male Chimerism Levels',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_males_with_40_to_79_percent_chimerism',
            header: '79-40% Male Chimerism Levels',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_males_with_0_to_39_percent_chimerism',
            header: '39-0% Male Chimerism Levels',
            editor: 'simplenumberfield'
        }
        ],

        'ES Cell Chimera Mating Details': [
        {
            dataIndex: 'test_cross_strain_name',
            header: 'Test Cross Strain',
            readOnly: true,
            sortable: false,
            renderer: 'safeTextRenderer',
            width: 200,
            editor: {
                xtype: 'simplecombo',
                store: Ext.Array.merge([''], window.MI_ATTEMPT_STRAIN_OPTIONS),
                storeOptionsAreSpecial: true,
                listConfig: {
                    minWidth: 200
                }
            }
        },
        {
            dataIndex: 'colony_background_strain_name',
            header: 'Colony Background Strain',
            readOnly: true,
            sortable: false,
            renderer: 'safeTextRenderer',
            width: 200,
            editor: {
                xtype: 'simplecombo',
                store: Ext.Array.merge([''], window.MI_ATTEMPT_STRAIN_OPTIONS),
                storeOptionsAreSpecial: true,
                listConfig: {
                    minWidth: 200
                }
            }
        },
        {
            xtype: 'simpledatecolumn',
            dataIndex: 'date_chimeras_mated',
            header: 'Date Chimeras Mated'
        },
        {
            dataIndex: 'number_of_chimera_matings_attempted',
            header: '# Chimera Mating Attempted',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_chimera_matings_successful',
            header: '# Chimera Matings Successful',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_chimeras_with_glt_from_cct',
            header: '# Chimeras with Germline Transmission from CCT',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_chimeras_with_glt_from_genotyping',
            header: 'No. Chimeras with Germline Transmission from Genotyping',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_chimeras_with_0_to_9_percent_glt',
            header: '# Chimeras with 0-9% GLT',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_chimeras_with_10_to_49_percent_glt',
            header: '# Chimeras with 10-49% GLT',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_chimeras_with_50_to_99_percent_glt',
            header: 'No. Chimeras with 50-99% GLT',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_chimeras_with_100_percent_glt',
            header: 'No. Chimeras with 100% GLT',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'total_f1_mice_from_matings',
            header: 'Total F1 Mice from Matings',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_cct_offspring',
            header: '# Coat Colour Transmission Offspring',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_het_offspring',
            header: '# Het Offspring',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_live_glt_offspring',
            header: '# Live GLT Offspring',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'mouse_allele_type',
            header: 'Mouse Allele Type',
            editor: {
                xtype: 'simplecombo',
                store: window.MI_ATTEMPT_MOUSE_ALLELE_TYPE_OPTIONS,
                listConfig: {
                    minWidth: 300
                }
            }
        },
        {
            dataIndex: 'mouse_allele_symbol',
            header: 'Mouse Allele Symbol',
            readOnly: true
        }
        ],

        'ES Cell QC Details': [
        {
            dataIndex: 'qc_southern_blot_result',
            header: 'Southern Blot',
            sortable: false,
            editor: 'qccombo'
        },
        {
            dataIndex: 'qc_five_prime_lr_pcr_result',
            header: 'Five Prime LR PCR',
            sortable: false,
            editor: 'qccombo'
        },
        {
            dataIndex: 'qc_five_prime_cassette_integrity_result',
            header: 'Five Prime Cassette Integrity',
            sortable: false,
            editor: 'qccombo'
        },
        {
            dataIndex: 'qc_tv_backbone_assay_result',
            header: 'TV Backbone Assay',
            sortable: false,
            editor: 'qccombo'
        },
        {
            dataIndex: 'qc_neo_count_qpcr_result',
            header: 'Neo Count QPCR',
            sortable: false,
            editor: 'qccombo'
        },
        {
            dataIndex: 'qc_lacz_count_qpcr_result',
            header: 'Lacz Count QPCR',
            sortable: false,
            editor: 'qccombo'
        },
        {
            dataIndex: 'qc_neo_sr_pcr_result',
            header: 'Neo SR PCR',
            sortable: false,
            editor: 'qccombo'
        },
        {
            dataIndex: 'qc_loa_qpcr_result',
            header: 'LOA QPCR',
            sortable: false,
            editor: 'qccombo'
        },
        {
            dataIndex: 'qc_homozygous_loa_sr_pcr_result',
            header: 'Homozygous LOA SR PCR',
            sortable: false,
            editor: 'qccombo'
        },
        {
            dataIndex: 'qc_lacz_sr_pcr_result',
            header: 'LacZ SR PCR',
            sortable: false,
            editor: 'qccombo'
        },
        {
            dataIndex: 'qc_mutant_specific_sr_pcr_result',
            header: 'Mutant Specific SR PCR',
            sortable: false,
            editor: 'qccombo'
        },
        {
            dataIndex: 'qc_loxp_confirmation_result',
            header: 'LoxP Confirmation',
            sortable: false,
            editor: 'qccombo'
        },
        {
            dataIndex: 'qc_three_prime_lr_pcr_result',
            header: 'Three Prime LR PCR',
            sortable: false,
            editor: 'qccombo'
        },
        {
            dataIndex: 'qc_critical_region_qpcr_result',
            header: 'Critical Region QPCR',
            sortable: false,
            editor: 'qccombo'
        },
        {
            dataIndex: 'qc_loxp_srpcr_result',
            header: 'Loxp SRPCR',
            sortable: false,
            editor: 'qccombo'
        },
        {
            dataIndex: 'qc_loxp_srpcr_and_sequencing_result',
            header: 'Loxp SRPRC and Sequencing',
            sortable: false,
            editor: 'qccombo'
        },
        {
            dataIndex: 'report_to_public',
            header: 'Report to Public',
            xtype: 'boolgridcolumn'
        },
        {
            dataIndex: 'is_active',
            header: 'Active?',
            xtype: 'boolgridcolumn'
        },
        {
            dataIndex: 'is_released_from_genotyping',
            header: 'Released From Genotyping',
            xtype: 'boolgridcolumn'
        }
        ],

        'Crispr Transfer Details': [
        {
            dataIndex: 'crsp_total_embryos_injected',
            header: '# Embryos Injected',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'crsp_total_embryos_survived',
            header: '# Embryos Survived',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'crsp_total_transfered',
            header: '# Transferred',
            editor: 'simplenumberfield'
        }
        ],

        'Crispr Founder Details': [
        {
            dataIndex: 'crsp_no_founder_pups',
            header: '# No Pups',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'founder_pcr_num_assays',
            header: '# PCR Assays',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'founder_pcr_num_positive_results',
            header: '# PCR +ve Results',
            editor: 'simplenumberfield'
        },
                {
            dataIndex: 'founder_surveyor_num_assays',
            header: '# Surveyor Assays',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'founder_surveyor_num_positive_results',
            header: '# Surveyor +ve Results',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'founder_t7en1_num_assays',
            header: '# T7EN1 Assays',
            editor: 'simplenumberfield'
        },
                {
            dataIndex: 'founder_t7en1_num_positive_results',
            header: '# T7EN1 +ve Assays',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'founder_loa_num_assays',
            header: '# LOA Assays',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'founder_loa_num_positive_results',
            header: '# LOA +ve Results',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'crsp_total_num_mutant_founders',
            header: '# Mutants',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'crsp_num_founders_selected_for_breading',
            header: '# For Breeding',
            editor: 'simplenumberfield'
        }
        ],

        'Crispr F1 Details': [
        ],

        'Crispr QC Details': [
        ]
    },

    additionalViewColumns: {
        'Summary': [
        'emma_status',
        'mouse_allele_type',
        'mouse_allele_symbol'
        ]
    }
// END COLUMN DEFINITION - ALWAYS keep at bottom of file for easier organization

});
