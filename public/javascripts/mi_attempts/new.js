Ext.namespace('Imits.MiAttempts.New');
Ext.require ([
  'MiPlanListViewModel'
])
Ext.onReady(function() {
    processRestOfForm();

    var panel = Ext.create('Imits.MiAttempts.New.EsCellSelectorForm', {
        renderTo: 'es-cell-selector'
    });
    var panel2 = Ext.create('Imits.MiAttempts.New.MutagenesisFactorSelectorForm', {
        renderTo: 'mutagenesis-factor-selector'
    });
    var ignoreWarningsButton = Ext.get('ignore-warnings');
    if(ignoreWarningsButton) {
        ignoreWarningsButton.addListener('click', function() {
            Imits.MiAttempts.New.restOfForm.ignoreWarningsField.dom.value = true;
            Imits.MiAttempts.New.restOfForm.submitButton.onClickHandler();
        });
    }
});

function processRestOfForm() {
    var restOfForm = Ext.get('rest-of-form');
    restOfForm.hidden = true;
    var store = Ext.create('Ext.data.JsonStore', {
        model: 'MiPlanListViewModel',
        storeId: 'store',
        proxy: {
            type: 'ajax',
            url: window.basePath + '/mi_plans/search_for_available_mi_attempt_plans.json'
        },
    });

    var listView = Ext.create('Ext.grid.Panel', {
        width:1000,
        height:250,
        title:'Select a Plan',
        renderTo: 'mi_plan_list',
        store: store,
        multiSelect: false,
        viewConfig: {
            emptyText: 'No images to display'
        },

        columns: [{
            text: 'Consortium',
            flex: 50,
            dataIndex: 'consortium_name'
        },{
            text: 'Production Centre',
            flex: 50,
            dataIndex: 'production_centre_name'
        },{
            text: 'Sub Project',
            flex: 40,
            dataIndex: 'sub_project_name'
        },{
            text: 'Knockout First Tm1a',
            flex: 60,
            dataIndex: 'is_conditional_allele'
        },{
            text: 'Conditional tm1c',
            flex: 50,
            dataIndex: 'conditional_tm1c'
        },{
            text: 'Deletion',
            flex: 30,
            dataIndex: 'is_deletion_allele'
        },{
            text: 'Cre Knock In',
            flex: 40,
            dataIndex: 'is_cre_knock_in_allele'
        },{
            text: 'Cre Bac',
            flex: 30,
            dataIndex: 'is_cre_bac_allele'
        },{
            text: 'Point Mutation',
            flex: 40,
            dataIndex: 'point_mutation'
        },{
            text: 'Conditional Point Mutation',
            flex: 70,
            dataIndex: 'conditional_point_mutation'
        },{
            text: 'Active',
            flex: 40,
            dataIndex: 'is_active'
        }
        ]
    });

        listView.on('selectionchange', function(view, nodes){
        restOfForm.getInputElement("mi_attempt[mi_plan_id]").set({ value: nodes[0].get('id') });
    });

    restOfForm.getInputElement = function(name) {
        return Ext.get(Ext.Array.filter(Ext.query('#rest-of-form input'), function(i) {
            return i.name === name;
        })[0]);
    }

    restOfForm.showIfHidden = function() {
        if(this.hidden == true) {
            this.setVisible(true, true);
            this.hidden = false;
        }
    }

    restOfForm.esCellNameField = restOfForm.getInputElement('mi_attempt[es_cell_name]');

    restOfForm.setEsCellDetails = function(esCellName, esCellMarkerSymbol) {
        this.esCellNameField.set({
            value: esCellName
        });
        restOfForm.esCellMarkerSymbol = esCellMarkerSymbol;
    }

    restOfForm.getEsCellName = function() {
        return this.esCellNameField.getValue();
    }

    restOfForm.set_mi_plan_selection = function(MarkerSymbol){

        if (MarkerSymbol){
            store.load({params: {marker_symbol: MarkerSymbol}});
        };
    }

    if(restOfForm.getEsCellName() == '') {
        restOfForm.setVisible(false, false);
        restOfForm.hidden = true;
    } else {
        restOfForm.hidden = false;
    }

    restOfForm.ignoreWarningsField = restOfForm.getInputElement("ignore_warnings");
    var esCellMarkerSymbolField = restOfForm.getInputElement("mi_attempt[es_cell_marker_symbol]");
    var MarkerSymbolValue = esCellMarkerSymbolField.getValue();
    restOfForm.esCellMarkerSymbol = MarkerSymbolValue;
    if (MarkerSymbolValue){
        restOfForm.set_mi_plan_selection(MarkerSymbolValue);
    }
    esCellMarkerSymbolField.remove();

    restOfForm.submitButton = Ext.get('mi_attempt_submit');
    restOfForm.submitButton.onClickHandler = function() {

        this.dom.disabled = 'disabled';
        Ext.getBody().addCls('wait');
        var form = this.up('form');
        form.dom.submit();
    }

    restOfForm.submitButton.addListener('click', restOfForm.submitButton.onClickHandler, restOfForm.submitButton);
    Imits.MiAttempts.New.restOfForm = restOfForm;
}

Ext.define('Imits.MiAttempts.New.EsCellSelectorForm', {
    extend: 'Ext.panel.Panel',
    layout: {
        type: 'vbox',
        align: 'stretch'
    },
    ui: 'plain',
    width: 300,
    height: 70,

    initComponent: function() {
        this.callParent();

        this.add(Ext.create('Ext.form.Label', {
            text: 'Marker symbol',
            margin: '0 0 2 0'
        }));

        var markerSymbolHtml = Imits.MiAttempts.New.restOfForm.esCellMarkerSymbol;
        if(Ext.isEmpty(markerSymbolHtml)) {
            markerSymbolHtml = '&nbsp;';
        }
        this.esCellMarkerSymbolDiv = Ext.create('Ext.Component', {
            html: markerSymbolHtml,
            margin: '0 0 5 0'
        });
        this.add(this.esCellMarkerSymbolDiv);

        this.add(Ext.create('Ext.form.Label', {
            text: 'Select an ES cell clone',
            padding: '0 0 5 0'
        }));

        this.esCellNameTextField = Ext.create('Ext.form.field.Text', {
            disabled: true,
            style: {
                color: 'black'
            }
        });

        this.add(Ext.create('Ext.panel.Panel', {
            layout: {
                type: 'hbox'
            },
            ui: 'plain',
            items: [
            this.esCellNameTextField,
            {
                xtype: 'button',
                margins: {
                    left: 5,
                    right: 0,
                    top: 0,
                    bottom: 0
                },
                text: 'Select',
                listeners: {
                    click: function() {
                        this.window.show();
                    },
                    scope: this
                }
            }
            ]
        }));

        this.addListener('render', this.renderHandler, this);

        this.window = Ext.create('Imits.MiAttempts.New.EsCellSelectorWindow', {
            esCellSelectorForm: this
        });
    },

    onEsCellNameSelected: function(esCellName, esCellMarkerSymbol) {
        this.esCellNameTextField.setValue(esCellName);
        this.esCellMarkerSymbolDiv.update(esCellMarkerSymbol);
        this.window.hide();

        Imits.MiAttempts.New.restOfForm.set_mi_plan_selection(esCellMarkerSymbol);

        Imits.MiAttempts.New.restOfForm.setEsCellDetails(esCellName, esCellMarkerSymbol);
        Imits.MiAttempts.New.restOfForm.showIfHidden();
    },

    renderHandler: function() {
        var defaultEsCellName = Imits.MiAttempts.New.restOfForm.getEsCellName();
        if(defaultEsCellName != '') {
            this.esCellNameTextField.setValue(defaultEsCellName);
        }
    }
});

Ext.define('Imits.MiAttempts.New.EsCellSelectorWindow', {
    extend: 'Imits.widget.Window',

    title: 'Search for ES cells',
    resizable: false,
    layout: 'fit',
    closeAction: 'hide',
    width: 550,
    height: 300,
    y: 175,

    initComponent: function() {
        this.callParent();

        this.esCellSearchTab = Ext.create('Imits.MiAttempts.New.SearchTab', {
            esCellSelectorForm: this.initialConfig.esCellSelectorForm,
            title: 'Search by ES cell name',
            searchBoxLabel: 'Enter ES cell name',
            searchParam: 'es_cell_name'
        });

        this.markerSymbolSearchTab = new Imits.MiAttempts.New.SearchTab({
            esCellSelectorForm: this.initialConfig.esCellSelectorForm,
            title: 'Search by marker symbol',
            searchBoxLabel: 'Enter marker symbol',
            searchParam: 'marker_symbol'
        });

        this.tabPanel = Ext.create('Ext.tab.Panel', {
            layout: 'fit',
            ui: 'plain',
            activeTab: 0,
            items: [
            this.markerSymbolSearchTab,
            this.esCellSearchTab
            ]
        });

        this.tabPanel.addListener('tabchange', function(panel, newTab) {
            newTab.searchBox.focus(true, 100);
        });

        this.addListener('show', function() {
            this.tabPanel.getActiveTab().searchBox.focus(true, 100);
        });

        this.add(this.tabPanel);
    }

});

Ext.define('Imits.MiAttempts.New.SearchTab', {
    extend: 'Ext.panel.Panel',
    ui: 'plain',
    layout: {
        type: 'vbox',
        align: 'stretch'
    },

    padding: {
        left: 10,
        top: 0,
        right: 10,
        bottom: 0
    },

    performSearch: function() {
        var urlParams = {}
        urlParams[this.initialConfig.searchParam] = this.searchBox.getValue();
        this.esCellSelectorForm.window.showLoadMask();
        Ext.Ajax.request({
            method: 'GET',
            url: window.basePath + '/targ_rep/es_cells/mart_search.json',
            params: urlParams,
            success: function(response) {
                var data = Ext.decode(response.responseText);
                this.esCellsList.getStore().loadData(data, false);
                this.esCellSelectorForm.window.hideLoadMask();
            },
            scope: this
        });
    },

    initComponent: function() {
        this.callParent();

        this.searchBox = Ext.create('Ext.form.field.Text', {
            name: this.initialConfig.searchParam + '-search-box',
            selectOnFocus: true,
            listeners: {
                specialkey: function(field, e) {
                    if(e.getKey() == e.ENTER) {
                        this.performSearch();
                    }
                },
                scope: this
            }
        });

        this.add(Ext.create('Ext.form.Label', {
            text: this.initialConfig.searchBoxLabel,
            margin: {
                top: 3,
                bottom: 3,
                left: 0,
                right: 0
            }
        }));

        this.add(Ext.create('Ext.panel.Panel', {
            layout: {
                type: 'hbox'
            },
            ui: 'plain',
            items: [
            this.searchBox,
            {
                xtype: 'button',
                text: 'Search',
                margins: {
                    left: 5,
                    top: 0,
                    right: 0,
                    bottom: 0
                },
                listeners: {
                    'click': {
                        fn: this.performSearch,
                        scope: this
                    }
                }
            }
            ]
        }));

        this.add(Ext.create('Ext.form.Label', {
            text: 'Choose an ES cell clone to micro-inject',
            margin: {
                top: 5,
                bottom: 3,
                left: 0,
                right: 0
            }
        }));

        this.esCellsList = Ext.create('Imits.MiAttempts.New.EsCellsList', {
            esCellSelectorForm: this.initialConfig.esCellSelectorForm
        });
        this.add(this.esCellsList);
    }
});

Ext.define('Imits.MiAttempts.New.EsCellsList', {
    extend: 'Ext.grid.Panel',
    height: 150,
    store: {
        fields: ['name', 'marker_symbol', 'pipeline_name', 'mutation_subtype', 'production_qc_loxp_screen'],
        data: {
            'rows': []
        },
        proxy: {
            type: 'memory',
            reader: {
                type: 'json',
                root: 'rows'
            }
        }
    },

    bodyStyle: {
        cursor: 'default'
    },
    title: null,
    columns: [
    {
        header: 'ES Cell',
        dataIndex: 'name',
        width: 100
    },
    {
        header: 'Marker Symbol',
        dataIndex: 'marker_symbol',
        width: 90
    },
    {
        header: 'Pipeline',
        dataIndex: 'pipeline_name',
        width: 80
    },
    {
        header: 'Mutation Subtype',
        dataIndex: 'mutation_subtype',
        flex: 1
    },
    {
        header: 'LoxP Screen',
        dataIndex: 'production_qc_loxp_screen',
        width: 90
    }
    ],

    initComponent: function() {
        this.callParent();

        this.addListener('itemclick', function(theView, record) {
            var esCellName = record.data['name'];
            this.initialConfig.esCellSelectorForm.onEsCellNameSelected(record.data['name'], record.data['marker_symbol']);
        });
    }
});

Ext.define('Imits.MiAttempts.New.MutagenesisFactorSelectorForm', {
    extend: 'Ext.panel.Panel',
    layout: {
        type: 'vbox',
        align: 'stretch'
    },
    ui: 'plain',
    width: 300,
    height: 70,

    initComponent: function() {
        this.callParent();

        this.MutagenesisFactorField = this.add(Ext.create('Ext.form.Label', {
            text: 'Create a Mutagenesis Factor',
            padding: '0 0 5 0',
            margins: {
                    left: 5,
                    right: 0,
                    top: 5,
                    bottom: 0
                }
        }));

        this.add(Ext.create('Ext.panel.Panel', {
            layout: {
                type: 'hbox'
            },
            ui: 'plain',
            items: [
            this.MutagenesisFactorField,
            {
                xtype: 'button',
                margins: {
                    left: 10,
                    right: 0,
                    top: 0,
                    bottom: 0
                },
                text: 'Select',
                listeners: {
                    click: function() {
                        this.window.show();
                    },
                    scope: this
                }
            }
            ]
        }));
        this.window = Ext.create('Imits.MiAttempts.New.MutagenesisFactorSelectorWindow', {
            MutagenesisFactorSelectorForm: this
        });
    }
});

Ext.define('Imits.MiAttempts.New.MutagenesisFactorSelectorWindow', {
    extend: 'Imits.widget.Window',

    title: 'Create mutation Factor',
    resizable: false,
    layout: 'fit',
    closeAction: 'hide',
    width: 800,
    height: 600,
    y: 175,

    initComponent: function() {
        this.callParent();

        this.crisprSearch = new Imits.MiAttempts.New.SearchForCrisprs({
            MutagenesisFactorSelectorForm: this.initialConfig.MutagenesisFactorSelectorForm,
            title: 'Search for crisprs',
            searchBoxLabel: 'Enter marker symbol',
            searchParam: 'marker_symbol'
        });


//        this.crisprSearchTab = new Imits.MiAttempts.New.SearchForCrisprsTab({
//            MutagenesisFactorSelectorForm: this.initialConfig.MutagenesisFactorSelectorForm,
//            title: 'Search for crisprs',
//            searchBoxLabel: 'Enter marker symbol',
//            searchParam: 'marker_symbol'
//        });

//        this.crisprPairSearchTab = new Imits.MiAttempts.New.SearchForCrisprsTab({
//            MutagenesisFactorSelectorForm: this.initialConfig.MutagenesisFactorSelectorForm,
//            title: 'Search for crispr pairs',
//            searchBoxLabel: 'Enter marker symbol',
//            searchParam: 'marker_symbol'
//        });

//        this.tabPanel = Ext.create('Ext.tab.Panel', {
//            layout: 'fit',
//            ui: 'plain',
//            activeTab: 0,
//            items: [
//            this.crisprSearchTab,
//            this.crisprPairSearchTab
//            ]
//        });

//        this.add(this.tabPanel);
          this.add(this.crisprSearch);
    }
});


Ext.define('Imits.MiAttempts.New.SearchForCrisprs', {
//Ext.define('Imits.MiAttempts.New.SearchForCrisprsTab', {
    extend: 'Ext.panel.Panel',
    ui: 'plain',
    layout: {
        type: 'vbox',
        align: 'stretch'
    },

    margin: {
        left: 10,
        top: 10,
        right: 10,
        bottom: 0
    },

    performSearch: function() {
        var urlParams = {}
        urlParams[this.initialConfig.searchParam] = this.searchBox.getValue();
        urlParams['species'] = 'Mouse';
        this.MutagenesisFactorSelectorForm.window.showLoadMask();
        Ext.Ajax.request({
            method: 'GET',
            url: window.basePath + '/targ_rep/wge_searches/exon_search.json',
            params: urlParams,
            success: function(response) {
                var data = Ext.decode(response.responseText);
                this.crisprselect.exonsList.getStore().loadData(data, false);
                this.MutagenesisFactorSelectorForm.window.hideLoadMask();
            },
            scope: this
        });
    },

    initComponent: function() {
        this.callParent();

        this.searchBox = Ext.create('Ext.form.field.Text', {
            name: this.initialConfig.searchParam + '-search-box',
            selectOnFocus: true,
            margin: {
                top: 8,
                bottom: 3,
                left: 10,
                right: 0
            },
            listeners: {
                specialkey: function(field, e) {
                    if(e.getKey() == e.ENTER) {
                        this.performSearch();
                    }
                },
                scope: this
            }
        });

        this.add(Ext.create('Ext.form.Label', {
            text: this.initialConfig.searchBoxLabel,
            margin: {
                top: 8,
                bottom: 3,
                left: 10,
                right: 0
            }
        }));

        this.add(Ext.create('Ext.panel.Panel', {
            layout: {
                type: 'hbox'
            },
            ui: 'plain',
            items: [
            this.searchBox,
            {
                xtype: 'button',
                text: 'Search',
                margins: {
                    left: 4,
                    top: 9,
                    right: 0,
                    bottom: 0
                },
                listeners: {
                    'click': {
                        fn: this.performSearch,
                        scope: this
                    }
                }
            }
            ]
        }));

        this.crisprselect = Ext.create('Imits.MiAttempts.New.SelectCrisprList', {
            MutagenesisFactorSelectorForm: this.initialConfig.MutagenesisFactorSelectorForm
        });
        this.add(this.crisprselect);
    }
});

Ext.define('Imits.MiAttempts.New.SelectCrisprList', {
  extend: 'Ext.panel.Panel',
  ui: 'plain',
  layout: {
    type: 'hbox',
    align: 'stretch'
  },

  initComponent: function() {
      this.callParent();

      this.crisprList = Ext.create('Imits.MiAttempts.New.CrisprList', {
           MutagenesisFactorSelectorForm: this.initialConfig.MutagenesisFactorSelectorForm
      });

      this.crisprpairList = Ext.create('Imits.MiAttempts.New.CrisprPairsList', {
           MutagenesisFactorSelectorForm: this.initialConfig.MutagenesisFactorSelectorForm
      });

      this.exonsList = Ext.create('Imits.MiAttempts.New.ExonsList', {
           MutagenesisFactorSelectorForm: this.initialConfig.MutagenesisFactorSelectorForm
      });
      this.tabPanel = Ext.create('Ext.tab.Panel', {
          layout: 'fit',
          ui: 'plain',
          activeTab: 0,
          items: [
              this.crisprList,
              this.crisprpairList
          ]
      });
    this.add([this.exonsList, this.tabPanel]);
  }

});


Ext.define('Imits.MiAttempts.New.ExonsList', {
    extend: 'Ext.grid.Panel',
    height: 260,
    margin: {
        left: 10,
        top: 25,
        right: 5,
        bottom: 0
    },
    store: {
        fields: ['exon_id', 'value', 'rank'],
        data: {
            'rows': []
        },
        proxy: {
            type: 'memory',
            reader: {
                type: 'json',
                root: 'exons'
            }
        }
    },

    bodyStyle: {
        cursor: 'default'
    },
    title: null,
    columns: [
    {
        header: 'Exon',
        dataIndex: 'exon_id',
        width: 180
    }
    ],

    initComponent: function() {
        this.callParent();

        this.addListener('itemclick', function(theView, record) {
          var urlParams = {}
          urlParams['exon_id[]'] = record.data['value'];
          this.MutagenesisFactorSelectorForm.window.showLoadMask();
          var url = this.MutagenesisFactorSelectorForm.window.crisprSearch.crisprselect.tabPanel.getActiveTab().url;
          Ext.Ajax.request({
            method: 'GET',
            url: window.basePath + url,
            params: urlParams,
            success: function(response) {
                var data = Ext.decode(response.responseText);
                this.MutagenesisFactorSelectorForm.window.crisprSearch.crisprselect.tabPanel.getActiveTab().getStore().loadData(data, false);
                this.MutagenesisFactorSelectorForm.window.hideLoadMask();
            },
            scope: this
        });
      });
    }
});

Ext.define('Imits.MiAttempts.New.CrisprList', {
    extend: 'Ext.grid.Panel',
    height: 260,
    width: 550,
    store: {
        fields: ['chr_end', 'chr_start', 'seq' ],
        data: {
            'rows': []
        },
        pageSize:500,
        proxy: {
            type: 'memory',
            reader: {
                type: 'json',
                root: 'exons'
            }
        }
    },

    bodyStyle: {
        cursor: 'default'
    },
    title: 'Crisprs',
    columns: [
    {
        header: 'Sequence',
        dataIndex: 'seq',
        width: 250
    },
    {
        header: 'Chr Start',
        dataIndex: 'chr_start',
        width: 80
    },
    {
        header: 'Chr End',
        dataIndex: 'chr_end',
        width: 80
    }
    ],

    initComponent: function() {
        this.callParent();
        this.url = '/targ_rep/wge_searches/crispr_search.json';
  //      this.addListener('itemclick', function(theView, record) {
  //          var species = 'Mouse'
  //          var esCellName = record.data['exon_id'];
  //      });
    }
});

Ext.define('Imits.MiAttempts.New.CrisprPairsList', {
    extend: 'Ext.grid.Panel',
    height: 260,
    width: 550,
    store: {
        fields: ['left_crispr', 'left_crispr_chr_start', 'left_crispr_chr_end', 'left_crispr_chr', 'right_crispr', 'right_crispr_chr_start', 'right_crispr_chr_end', 'right_crispr_chr' ],
        data: {
            'rows': []
        },
        pageSize:500,
        proxy: {
            type: 'memory',
            reader: {
                type: 'json',
                root: 'exons'
            }
        }
    },

    bodyStyle: {
        cursor: 'default'
    },
    title: 'Crispr Pairs',
    columns: [
    {
        header: 'Left Crispr',
        dataIndex: 'left_crispr',
        width: 250
    },
    {
        header: 'Right Crispr',
        dataIndex: 'right_crispr',
        width: 250
    }
    ],

    initComponent: function() {
        this.callParent();
        this.url = '/targ_rep/wge_searches/crispr_pair_search.json';
  //      this.addListener('itemclick', function(theView, record) {
  //          var species = 'Mouse'
  //          var esCellName = record.data['exon_id'];
  //      });
    }
});
