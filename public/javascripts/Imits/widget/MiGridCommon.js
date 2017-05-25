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
                case 'Summary':
                    // filter cas9 inactivated
                    grid.deactivateCrisprFilter();
                    break;
                case 'ES Cell Summary':
                case 'ES Cell Transfer Details':
                case 'ES Cell Litter Details':
                case 'ES Cell Chimera Mating Details':
                case 'ES Cell QC Details':
                case 'ES Cell All Details':
                    // filter cas9 off
                    grid.activateCrisprFilterWithValue(false);
                    break;
                case 'Crispr Summary':
                case 'Crispr Transfer Details':
                case 'Crispr Founder Details':
                case 'Crispr F1 Details':
                case 'Crispr QC Details':
                case 'Crispr All Details':
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

            grid.reconfigure(null, grid.initialConfig.columns)

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
//            switch(item.text) {
//                case 'Summary':
//                    grid.moveColumnToIndex("mi_plan_mutagenesis_via_crispr_cas9", 11);
//                    break;
//                case 'ES Cell Transfer Details':
//                case 'ES Cell Litter Details':
//                case 'ES Cell Chimera Mating Details':
//                case 'ES Cell QC Details':
//                case 'ES Cell All Details':
//                    break;
//                default:
//                    break;
//            };

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
        var crisprCommonColumns = Ext.pluck(this.groupedColumns.crispr_common, 'dataIndex');;

        var esCellAllDetailView = [];
        var CrisprAllDetailView = [];

        // First generate the groups from the groupedColumns
        Ext.Object.each(this.groupedColumns, function(viewName, viewColumnConfigs) {
            // switch what columns are displayed based on view name
            switch(viewName) {
                case 'common':
                case 'es_cell_common':
                case 'crispr_common':
                case 'none':
                    return;
                case 'Summary':
                    var viewColumns = Ext.pluck(viewColumnConfigs, 'dataIndex');
                    views[viewName] = viewColumns;
                  break;
                case 'ES Cell Summary':
                case 'ES Cell Transfer Details':
                case 'ES Cell Litter Details':
                case 'ES Cell Chimera Mating Details':
                case 'ES Cell QC Details':
                    var viewColumns = Ext.pluck(viewColumnConfigs, 'dataIndex');
                    views[viewName] = Ext.Array.merge(commonColumns, esCellCommonColumns, viewColumns);
                    esCellAllDetailView = Ext.Array.merge(commonColumns, esCellCommonColumns, esCellAllDetailView, viewColumns);
                    break;
                case 'Crispr Summary':
                case 'Crispr Transfer Details':
                case 'Crispr Founder Details':
                case 'Crispr F1 Details':
                case 'Crispr QC Details':
                    var viewColumns = Ext.pluck(viewColumnConfigs, 'dataIndex');
                    views[viewName] = Ext.Array.merge(commonColumns, crisprCommonColumns, viewColumns);
                    CrisprAllDetailView = Ext.Array.merge(commonColumns, crisprCommonColumns, CrisprAllDetailView, viewColumns);
                    break;
                default:
                    return;
            }
            views['ES Cell All Details'] = esCellAllDetailView;
            views['Crispr All Details'] = CrisprAllDetailView;
        });

        var grid = this;
        Ext.Object.each(this.additionalViewColumns, function(viewName) {
            views[viewName] = Ext.Array.merge(commonColumns, grid.additionalViewColumns[viewName], views[viewName]);
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
        onItemClick({text: 'Summary'});
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
            { text:'Summary', handler: onItemClick }//,
          //  { text:'Everything', handler: onItemClick }
        ];

        var esCellsMenuConfig = [
            { text:'ES Cell Summary', handler: onItemClick },
            { text:'ES Cell All Details', handler: onItemClick },
            { text:'ES Cell Transfer Details', handler: onItemClick },
            { text:'ES Cell Litter Details', handler: onItemClick },
            { text:'ES Cell Chimera Mating Details', handler: onItemClick },
            { text:'ES Cell QC Details', handler: onItemClick }
        ];

        var crisprsMenuConfig = [
            { text:'Crispr Summary', handler: onItemClick },
            { text:'Crispr All Details', handler: onItemClick },
            { text:'Crispr Transfer Details', handler: onItemClick },
            { text:'Crispr Founder Details', handler: onItemClick }//,
            // { text:'Crispr F1 Details', handler: onItemClick },
            // { text:'Crispr QC Details', handler: onItemClick },
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
            if (columns[index].dataIndex == dataIndex) {
                break;
            }
        }
        return index == columns.length ? -1 : index;
    },

    moveColumnToIndex: function(columnName, newColumnIndex) {
        var self = this;
        var col_index = grid.findColumnIndex(self.headerCt.getGridColumns(), columnName);
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
            dataIndex: 'marker_symbol',
            header: 'Marker Symbol',
            width: 85,
            readOnly: true,
            sortable: false,
        },
        {
            dataIndex: 'consortium_name',
            header: 'Consortium',
            readOnly: true,
            width: 150,
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
            dataIndex: 'colony_name',
            header: 'MI External Ref/ Colony Name',
            width: 180,
            editor: 'textfield',
            filter: {
                type: 'string',
                value: Imits.Util.extractValueIfExistent(window.MI_ATTEMPT_SEARCH_PARAMS, 'colony_name')
            }
        },
        {
            dataIndex: 'status_name',
            header: 'Status',
            width: 180,
            readOnly: true,
            sortable: false,
            filter: {
                type: 'list',
                options: window.MI_ATTEMPT_STATUS_OPTIONS,
                value: Imits.Util.extractValueIfExistent(window.MI_ATTEMPT_SEARCH_PARAMS, 'status_name')
            }
        },
        {
            dataIndex: 'genotyped_confirmed_colony_names',
            header: 'Genotype Confirmed Colonies',
            width: 180,
            editor: 'textfield',
            renderer: function(value, metaData, record){
                var genotype_confirmed_colony_names = record.get('genotyped_confirmed_colony_names').toString().replace('[', '').replace(']', '').split(',');
                var textToDisplay = genotype_confirmed_colony_names.join('<br><br>')
                return textToDisplay
                },
            sortable: false
        },
        {
            dataIndex: 'genotype_confirmed_allele_symbols',
            header: 'Mouse Allele Symbol',
            width: 180,
            readOnly: true,
            renderer: function(value, metaData, record){
                var genotype_confirmed_colony_names = record.get('genotype_confirmed_allele_symbols').toString().replace('[', '').replace(']', '').split(',');
                var textToDisplay = genotype_confirmed_colony_names.join('<br><br>')
                return textToDisplay
                },
            sortable: false
        }
        ],

        'Summary': [
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
        'Crispr Summary': [],
        'ES Cell Summary': [],
        'es_cell_common': [
        {
            xtype: 'simpledatecolumn',
            dataIndex: 'mi_date',
            header: 'MI Date',
            width: 90
        },
        {
            dataIndex: 'es_cell_name',
            header: 'ES Cell',
            readOnly: true,
            width: 140,
            sortable: false,
            filter: {
                type: 'string',
                value: Imits.Util.extractValueIfExistent(window.MI_ATTEMPT_SEARCH_PARAMS, 'es_cell_name')
            }
        },
        {
            dataIndex: 'es_cell_allele_symbol',
            header: 'Allele symbol',
            width: 180,
            readOnly: true,
            sortable: false
        }
        ],

        'crispr_common': [
        {
            xtype: 'simpledatecolumn',
            dataIndex: 'mi_date',
            header: 'MI Date',
            width: 90
        }
        ],

        'ES Cell Transfer Details': [
        {
            dataIndex: 'blast_strain_name',
            header: 'Blast Strain',
            sortable: false,
            renderer: 'safeTextRenderer',
            width: 150,
            editor: {
                xtype: 'simplecombo',
                store: Ext.Array.merge([''], window.MI_ATTEMPT_STRAIN_OPTIONS),
                storeOptionsAreSpecial: true,
                listConfig: {
                    minWidth: 160
                }
            }
        },
        {
            dataIndex: 'total_blasts_injected',
            header: 'Total Blasts Injected',
            width: 110,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'total_transferred',
            header: 'Total Transferred',
            width: 100,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_surrogates_receiving',
            header: '# Surrogates Receiving',
            width: 130,
            editor: 'simplenumberfield'
        }
        ],

        'ES Cell Litter Details': [
        {
            dataIndex: 'total_pups_born',
            header: 'Total Pups Born',
            width: 90,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'total_female_chimeras',
            header: 'Total Female Chimeras',
            width: 125,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'total_male_chimeras',
            header: 'Total Male Chimeras',
            width: 110,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'total_chimeras',
            header: 'Total Chimeras',
            width: 90,
            readOnly: true
        },
        {
            dataIndex: 'number_of_males_with_100_percent_chimerism',
            header: '100% Male Chimerism Levels',
            width: 155,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_males_with_80_to_99_percent_chimerism',
            header: '99-80% Male Chimerism Levels',
            width: 165,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_males_with_40_to_79_percent_chimerism',
            header: '79-40% Male Chimerism Levels',
            width: 170,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_males_with_0_to_39_percent_chimerism',
            header: '39-0% Male Chimerism Levels',
            width: 165,
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
            width: 160,
            editor: {
                xtype: 'simplecombo',
                store: Ext.Array.merge([''], window.MI_ATTEMPT_STRAIN_OPTIONS),
                storeOptionsAreSpecial: true,
                listConfig: {
                    minWidth: 160
                }
            }
        },
        {
            dataIndex: 'colony_background_strain_name',
            header: 'Colony Background Strain',
            readOnly: true,
            sortable: false,
            renderer: 'safeTextRenderer',
            width: 160,
            editor: {
                xtype: 'simplecombo',
                store: Ext.Array.merge([''], window.MI_ATTEMPT_STRAIN_OPTIONS),
                storeOptionsAreSpecial: true,
                listConfig: {
                    minWidth: 160
                }
            }
        },
        {
            xtype: 'simpledatecolumn',
            dataIndex: 'date_chimeras_mated',
            width: 120,
            header: 'Date Chimeras Mated'
        },
        {
            dataIndex: 'number_of_chimera_matings_attempted',
            header: '# Chimera Mating Attempted',
            width: 160,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_chimera_matings_successful',
            header: '# Chimera Matings Successful',
            width: 160,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_chimeras_with_glt_from_cct',
            header: '# Chimeras with Germline Transmission from CCT',
            width: 255,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_chimeras_with_glt_from_genotyping',
            header: 'No. Chimeras with Germline Transmission from Genotyping',
            width: 300,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_chimeras_with_0_to_9_percent_glt',
            header: '# Chimeras with 0-9% GLT',
            width: 145,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_chimeras_with_10_to_49_percent_glt',
            header: '# Chimeras with 10-49% GLT',
            width: 155,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_chimeras_with_50_to_99_percent_glt',
            header: 'No. Chimeras with 50-99% GLT',
            width: 165,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_chimeras_with_100_percent_glt',
            header: 'No. Chimeras with 100% GLT',
            width: 160,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'total_f1_mice_from_matings',
            header: 'Total F1 Mice from Matings',
            width: 145,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_cct_offspring',
            header: '# Coat Colour Transmission Offspring',
            width: 200,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_het_offspring',
            header: '# Het Offspring',
            width: 90,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_live_glt_offspring',
            header: '# Live GLT Offspring',
            width: 115,
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
        }
        ],

        'ES Cell QC Details': [
//        {
//            dataIndex: 'qc_southern_blot_result',
//            header: 'Southern Blot',
//            sortable: false,
//            width: 85,
//            editor: 'qccombo'
//        },
//        {
//            dataIndex: 'qc_five_prime_lr_pcr_result',
//            header: 'Five Prime LR PCR',
//            sortable: false,
//            width: 110,
//            editor: 'qccombo'
//        },
//        {
//            dataIndex: 'qc_five_prime_cassette_integrity_result',
//            header: 'Five Prime Cassette Integrity',
//            sortable: false,
//            width: 110,
//            editor: 'qccombo'
//        },
//        {
//            dataIndex: 'qc_tv_backbone_assay_result',
//            header: 'TV Backbone Assay',
//            sortable: false,
//            width: 110,
//            editor: 'qccombo'
//        },
//        {
//            dataIndex: 'qc_neo_count_qpcr_result',
//            header: 'Neo Count QPCR',
//            sortable: false,
//            width: 105,
//            editor: 'qccombo'
//        },
//        {
//            dataIndex: 'qc_lacz_count_qpcr_result',
//            header: 'Lacz Count QPCR',
//            sortable: false,
//            width: 105,
//            editor: 'qccombo'
//        },
//        {
//            dataIndex: 'qc_neo_sr_pcr_result',
//            header: 'Neo SR PCR',
//            sortable: false,
//            width: 75,
//            editor: 'qccombo'
//        },
//        {
//            dataIndex: 'qc_loa_qpcr_result',
//            header: 'LOA QPCR',
//            sortable: false,
//            width: 70,
//            editor: 'qccombo'
//        },
//        {
//            dataIndex: 'qc_homozygous_loa_sr_pcr_result',
//            header: 'Homozygous LOA SR PCR',
//            sortable: false,
//            width: 150,
//            editor: 'qccombo'
//        },
//        {
//            dataIndex: 'qc_lacz_sr_pcr_result',
//            header: 'LacZ SR PCR',
//            sortable: false,
//            width: 80,
//            editor: 'qccombo'
//        },
//        {
//            dataIndex: 'qc_mutant_specific_sr_pcr_result',
//            header: 'Mutant Specific SR PCR',
//            sortable: false,
//            width: 130,
//            editor: 'qccombo'
//        },
//        {
//            dataIndex: 'qc_loxp_confirmation_result',
//            header: 'LoxP Confirmation',
//            sortable: false,
//            width: 100,
//            editor: 'qccombo'
//        },
//        {
//            dataIndex: 'qc_three_prime_lr_pcr_result',
//            header: 'Three Prime LR PCR',
//            sortable: false,
//            width: 115,
//            editor: 'qccombo'
//        },
//        {
//            dataIndex: 'qc_critical_region_qpcr_result',
//            header: 'Critical Region QPCR',
//            sortable: false,
//            width: 115,
//            editor: 'qccombo'
//        },
//        {
//            dataIndex: 'qc_loxp_srpcr_result',
//            header: 'Loxp SRPCR',
//            sortable: false,
//            width: 80,
//            editor: 'qccombo'
//        },
//        {
//            dataIndex: 'qc_loxp_srpcr_and_sequencing_result',
//            header: 'Loxp SRPRC and Sequencing',
//            sortable: false,
//            width: 155,
//            editor: 'qccombo'
//        },
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
            width: 110,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'crsp_total_embryos_survived',
            header: '# Embryos Survived',
            width: 115,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'crsp_total_transfered',
            header: '# Transferred',
            width: 90,
            editor: 'simplenumberfield'
        }
        ],

        'Crispr Founder Details': [
        {
            dataIndex: 'crsp_no_founder_pups',
            header: '# No Pups',
            width: 65,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'founder_pcr_num_assays',
            header: '# PCR Assays',
            width: 80,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'founder_pcr_num_positive_results',
            header: '# PCR +ve Results',
            width: 105,
            editor: 'simplenumberfield'
        },
                {
            dataIndex: 'founder_surveyor_num_assays',
            header: '# Surveyor Assays',
            width: 105,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'founder_surveyor_num_positive_results',
            header: '# Surveyor +ve Results',
            width: 130,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'founder_t7en1_num_assays',
            header: '# T7EN1 Assays',
            width: 95,
            editor: 'simplenumberfield'
        },
                {
            dataIndex: 'founder_t7en1_num_positive_results',
            header: '# T7EN1 +ve Assays',
            width: 115,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'founder_loa_num_assays',
            header: '# LOA Assays',
            width: 90,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'founder_loa_num_positive_results',
            header: '# LOA +ve Results',
            width: 105,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'crsp_total_num_mutant_founders',
            header: '# Mutants',
            width: 60,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'crsp_num_founders_selected_for_breading',
            header: '# For Breeding',
            width: 90,
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
        'emma_status'
        ]
    }
// END COLUMN DEFINITION - ALWAYS keep at bottom of file for easier organization

});
