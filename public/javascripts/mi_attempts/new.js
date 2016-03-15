Ext.namespace('Imits.MiAttempts.New');
Ext.onReady(function() {

    Ext.select('#mi_attempt_individually_set_grna_concentrations').on("change", function(e) {
      div = Ext.select('.grna_concentration');

      if(this.checked) {
        div.show();
      } else {
        div.hide();
      }
   });

    processRestOfForm();

    EsCellPanel = Ext.create('Imits.MiAttempts.New.EsCellSelectorForm', {
        renderTo: 'es-cell-selector'
    });
    mutagensisFactorPanel = Ext.create('Imits.MiAttempts.New.MutagenesisFactorSelectorForm', {
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

    restOfForm.ignoreWarningsField = restOfForm.getInputElement("ignore_warnings");
    var esCellMarkerSymbolField = restOfForm.getInputElement("mi_attempt[es_cell_marker_symbol]");

    if(restOfForm.getEsCellName() != ''){
       var MarkerSymbolValue = esCellMarkerSymbolField.getValue();
       restOfForm.esCellMarkerSymbol = MarkerSymbolValue;
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
    height: 40,

    initComponent: function() {
        this.callParent();

        Ext.create('Ext.form.Label', {
            renderTo: 'es-cell-details',
            text: 'Marker symbol',
            margin: '0 0 2 0'
        });

        var markerSymbolHtml = Imits.MiAttempts.New.restOfForm.esCellMarkerSymbol;
        if(Ext.isEmpty(markerSymbolHtml)) {
            markerSymbolHtml = '&nbsp;';
        }
        this.esCellMarkerSymbolDiv = Ext.create('Ext.Component', {
            renderTo: 'es-cell-details',
            html: markerSymbolHtml,
            margin: '0 0 5 0'
        });

        this.esCellLable =Ext.create('Ext.form.Label', {
            text: 'Create ES Cell MI',
            margins: {
                left: 5,
                right: 0,
                top: 5,
                bottom: 0
            }
        });

        this.esCellNameTextField = Ext.create('Ext.form.field.Text', {
            renderTo: 'es-cell-details',
            disabled: true,
            style: {
                color: 'black'
            }
        });

        Ext.create('Ext.Button', {
            minHeight: 20,
            text: 'Select Different Es Cell Clone',
            renderTo: 'es-cell-details',
            handler: function() {
                        this.window.show();
                    },
                    scope: this
        });



        this.esCellNameSelect = Ext.create('Ext.panel.Panel', {
            layout: {
                type: 'hbox'
            },
            ui: 'plain',
            items: [
            this.esCellLable,
            {
                xtype: 'button',
                margins: {
                    left: 5,
                    right: 0,
                    top: 0,
                    bottom: 0
                },
                text: 'Select Clone',
                listeners: {
                    click: function() {
                        this.window.show();
                    },
                    scope: this
                }
            }
            ]
        });

        this.add(this.esCellNameSelect);
        this.addListener('render', this.renderHandler, this);

        this.window = Ext.create('Imits.MiAttempts.New.EsCellSelectorWindow', {
            esCellSelectorForm: this
        });
    },

    onEsCellNameSelected: function(esCellName, esCellMarkerSymbol) {
        this.esCellNameTextField.setValue(esCellName);
        this.esCellMarkerSymbolDiv.update(esCellMarkerSymbol);
        mutagensisFactorPanel.MutagenesisFactorCreateSelect.disable();
        this.window.hide();

        listView.set_mi_plan_selection(esCellMarkerSymbol);
        Ext.get('mi_attempt_mi_plan_id').set({
            value: ''
        });
        Imits.MiAttempts.New.restOfForm.setEsCellDetails(esCellName, esCellMarkerSymbol);
        var top = Ext.get('object-new-top');
        top.setVisible(false ,'display');
        top.hide();
        $('.object-es-cell').show();
        $('.object-crispr').hide();
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
            text: 'Create Crispr MI',
            padding: '0 0 5 0',
            margins: {
                    left: 5,
                    right: 0,
                    top: 5,
                    bottom: 0
                }
        }));

        this.MutagenesisFactorCreateSelect = this.add(Ext.create('Ext.panel.Panel', {
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
                text: 'Select Crisprs',
                listeners: {
                    click: function() {
                        this.window.show();
                    },
                    scope: this
                }
            }
            ]
        }));

        Ext.create('Ext.Button', {
            minHeight: 20,
            text: 'Edit Crispr Selection',
            renderTo: 'crispr_edit_button',
            handler: function() {

                // show crisprs already selected in crisprSelectionGrid
                var numberOfCripsrsSelected = Ext.get('crispr-table').query('tr').length;
                for (var i=0;i<numberOfCripsrsSelected;i++){
                    var addCrispr = {}
                    addCrispr['seq'] = Ext.get('mi_attempt_mutagenesis_factor_attributes_crisprs_attributes_' + i + '_sequence').getValue();
                    addCrispr['chr'] = Ext.get('mi_attempt_mutagenesis_factor_attributes_crisprs_attributes_' + i + '_chr').getValue();
                    addCrispr['chr_start'] = Ext.get('mi_attempt_mutagenesis_factor_attributes_crisprs_attributes_' + i + '_start').getValue();
                    addCrispr['chr_end'] = Ext.get('mi_attempt_mutagenesis_factor_attributes_crisprs_attributes_' + i + '_end').getValue();
                    addCrispr['grna_conentration'] = Ext.get('mi_attempt_mutagenesis_factor_attributes_crisprs_attributes_' + i + '_grna_conentration').getValue();

                    this.window.crisprSearch.crisprSelectionList.createCrispr(addCrispr)
                }

                // Auto fill marker_symbol if blank and find exons
                var formMarkerSymbol = Ext.get('marker_symbol').getValue();
                if (formMarkerSymbol !=  this.window.crisprSearch.searchBox.getValue()){
                    this.window.crisprSearch.searchBox.focus();
                    this.window.crisprSearch.searchBox.setValue(formMarkerSymbol);
                    this.window.show();
                    this.window.crisprSearch.performSearch();
                }
                else{
                  this.window.show();
                }

                if (formMarkerSymbol){
                    mutagensisFactorPanel.window.crisprSearch.searchBox.disable();
                    mutagensisFactorPanel.window.crisprSearch.searchButton.disable();
                }
            },
            scope: this
        });

        this.window = Ext.create('Imits.MiAttempts.New.MutagenesisFactorSelectorWindow', {
        });
    }
});

Ext.define('Imits.MiAttempts.New.MutagenesisFactorSelectorWindow', {
    extend: 'Imits.widget.Window',

    title: 'Create mutation Factor',
    resizable: false,
    layout: 'fit',
    closable: false,
    width: 845,
    height: 650,
    y: 175,

    initComponent: function() {
        this.callParent();

        this.crisprSearch = new Imits.MiAttempts.New.SearchForCrisprs({
            title: 'Search for crisprs',
            searchBoxLabel: 'Enter marker symbol',
            searchParam: 'marker_symbol'
        });

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
        mutagensisFactorPanel.window.showLoadMask();
        Ext.Ajax.request({
            method: 'GET',
            url: window.basePath + '/targ_rep/wge_searches/exon_search.json',
            params: urlParams,
            success: function(response) {
                var data = Ext.decode(response.responseText);
                mutagensisFactorPanel.window.crisprSearch.crisprFindSelect.exonSearch.exonsList.getStore().loadData(data, false);
                mutagensisFactorPanel.window.hideLoadMask();
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

        this.searchButton  = Ext.create('Ext.Button', {
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
            this.searchButton
            ]
        }));

        this.submitButtons = Ext.create('Ext.panel.Panel', {
            layout: {
                type: 'hbox'
            },
            ui: 'plain',
            items: [
                {
                xtype: 'button',
                text: 'Save',
                margins: {
                    left: 10,
                    top: 9,
                    right: 10,
                    bottom: 0
                    },
                listeners: {
                    'click':  function() {
                        var MarkerSymbol = mutagensisFactorPanel.window.crisprSearch.searchBox.getValue()
                        if (MarkerSymbol){
                          Ext.get('marker_symbol').set({
                              value: MarkerSymbol
                          });
                          var crispr = 'true';
                          listView.set_mi_plan_selection(MarkerSymbol, crispr);
                        }

                        var crisprTable = Ext.get('crispr-table');
                        var recordStore = mutagensisFactorPanel.window.crisprSearch.crisprSelectionList.getStore()
                        var newRecords = recordStore.getNewRecords();
                        var count_n = 0
                        //remove existing rows from crispr table
                        while (crisprTable.dom.firstChild) {
                            crisprTable.dom.removeChild(crisprTable.dom.firstChild);
                        };
                        newRecords.forEach(
                            function(item){
                                var tableRow ="<tr>\
<td><input type='hidden' id='mi_attempt_mutagenesis_factor_attributes_crisprs_attributes_" + count_n + "_sequence' name='mi_attempt[mutagenesis_factor_attributes][crisprs_attributes]["+ count_n + "][sequence]' value= " + item.data['seq'] + " >" + item.data['seq'] + "</td>\
<td><input type='hidden' id='mi_attempt_mutagenesis_factor_attributes_crisprs_attributes_"+ count_n + "_chr' name='mi_attempt[mutagenesis_factor_attributes][crisprs_attributes]["+ count_n + "][chr]' value= " + item.data['chr'] + " >" + item.data['chr'] + "</td>\
<td><input type='hidden' id='mi_attempt_mutagenesis_factor_attributes_crisprs_attributes_"+ count_n + "_start' name='mi_attempt[mutagenesis_factor_attributes][crisprs_attributes]["+ count_n + "][start]' value= " + item.data['chr_start'] + " >" + item.data['chr_start'] + "</td>\
<td><input type='hidden' id='mi_attempt_mutagenesis_factor_attributes_crisprs_attributes_"+ count_n + "_end' name='mi_attempt[mutagenesis_factor_attributes][crisprs_attributes]["+ count_n + "][end]' value= " +  item.data['chr_end'] + " >" +  item.data['chr_end'] + "</td>\
<td><div class='hidden grna_concentration'><input id='mi_attempt_mutagenesis_factor_attributes_crisprs_attributes_"+ count_n + "_grna_conentration' name='mi_attempt[mutagenesis_factor_attributes][crisprs_attributes]["+ count_n + "][grna_conentration]' value= " + " ></div></td>\
</tr>";

                                crisprTable.createChild(tableRow);
                                count_n += 1
                            }
                        );
                        var vectorAttribute = Ext.get('mi_attempt_mutagenesis_factor_attributes_vector_name');
                        var vectorValue = undefined;
                        if (vectorAttribute) {vectorValue = vectorAttribute.getValue()};
                        Ext.get('vector-container').dom.innerHTML = '';
                        Ext.create('Ext.form.Label', {
                            renderTo: 'vector-container',
                            text: 'Vector',
                            margin: '0 0 2 0'
                        });
                        var urlParams = {};
                        urlParams['marker_symbol'] = mutagensisFactorPanel.window.crisprSearch.searchBox.getValue();
                        Ext.Ajax.request({
                            method: 'GET',
                            url: window.basePath + '/genes/vectors.json',
                            params: urlParams,
                            success: function(response) {
                                var data = Ext.decode(response.responseText);
                                var options = '<option value=""></option>';
                                if (vectorValue){options += '<option value="' + vectorValue + '" selected>' + vectorValue + '</option>'};
                                var crisprtv = '<option value="" disabled>Targeted Vector</option>';
                                var oligo = '<option value="" disabled>Oligo</option>';
                                var escelltv = '<option value="" disabled>Targeted Vector</option>';
                                data.forEach(
                                    function(item){
                                        if (item.type =='TargRep::CrisprTargetedAllele'){
                                            crisprtv += '<option value="' + item.name + '">' + item.name + '</option>';
                                        }
                                        else if (item.type =='TargRep::HdrAllele'){
                                            oligo += '<option value="' + item.name + '">' + item.name + '</option>';
                                        }
                                        else if (item.type =='TargRep::TargetedAllele'){
                                            escelltv += '<option value="' + item.name + '">' + item.name + '</option>';
                                        }
                                    }
                                );
                                options += '<option value="" disabled>-- CRISPR --</option>' + crisprtv + oligo + '<option value="" disabled></option><option value="" disabled>-- ES CELL --</option>' + escelltv;
                                vectorHtml = '<select id="mi_attempt_mutagenesis_factor_attributes_vector_name" name="mi_attempt[mutagenesis_factor_attributes][vector_name]">' + options;
                                this.vectorDiv = Ext.create('Ext.Component', {
                                renderTo: 'vector-container',
                                html: vectorHtml,
                                margin: '0 0 5 0'
                            });
                            },
                            scope: this
                        });

                        var vectorConcentrationAttribute = Ext.get('mi_attempt_mutagenesis_factor_attributes_vector_oligo_concentration');
                        var vectorConcentrationValue = undefined;
                        if (vectorConcentrationAttribute) {vectorConcentrationValue = vectorConcentrationAttribute.getValue()};
                        Ext.get('grna-concentrations-equal-container').dom.innerHTML = '';
                        Ext.create('Ext.form.Label', {
                            renderTo: 'grna-concentrations-equal-container',
                            text: 'Vector Concentration (ng/uL)',
                            margin: '0 0 2 0'
                        });
                        vectorOligoConcentrationHtml = '<input id="mi_attempt_mutagenesis_factor_attributes_vector_oligo_concentration" name="mi_attempt[mutagenesis_factor_attributes][vector_oligo_concentration]" ';
                        if (vectorConcentrationValue){vectorOligoConcentrationHtml += 'value = "' + vectorConcentrationValue + '"'};
                        vectorOligoConcentrationHtml += ">"
                        Ext.create('Ext.Component', {
                            renderTo: 'grna-concentrations-equal-container',
                            html: vectorOligoConcentrationHtml,
                            margin: '0 0 5 0'
                        });

                        mutagensisFactorPanel.window.crisprSearch.crisprSelectionList.getStore().removeAll()

                        EsCellPanel.esCellNameTextField.disable();
                        EsCellPanel.esCellNameSelect.disable();
                        mutagensisFactorPanel.window.crisprSearch.searchBox.disable();
                        mutagensisFactorPanel.window.crisprSearch.searchButton.disable();

                        var top = Ext.get('object-new-top');
                        top.setVisible(false ,'display');
                        top.hide();

                        $('.object-es-cell').hide();
                        $('.object-crispr').show();
                        $('#genotype_primer_field_set').show();

                        Imits.MiAttempts.New.restOfForm.showIfHidden();
                        mutagensisFactorPanel.window.hide();

                        }
                    }
                },
                {
                xtype: 'button',
                text: 'Cancel',
                margins: {
                    left: 10,
                    top: 9,
                    right: 10,
                    bottom: 0
                    },
                listeners: {
                    'click': function() {
                        mutagensisFactorPanel.window.crisprSearch.crisprSelectionList.getStore().removeAll()
                        mutagensisFactorPanel.window.hide();
                        }
                    }
                }
            ]
        });



        this.crisprFindSelect = Ext.create('Imits.MiAttempts.New.FindSelectCrisprList', {});

        this.crisprSelectionList = Ext.create('Imits.MiAttempts.New.CrisprSelectionList', {
        });

      this.add(this.crisprFindSelect, this.crisprSelectionList, this.submitButtons);
    }
});

Ext.define('Imits.MiAttempts.New.FindSelectCrisprList', {
    extend: 'Ext.panel.Panel',
    ui: 'plain',
    layout: {
        type: 'hbox',
        align: 'stretch'
    },

    initComponent: function() {
        this.callParent();

        this.exonSearch = Ext.create('Imits.MiAttempts.New.SelectCrisprList', {
        });

        this.crisprSelectBySequence = Ext.create('Imits.MiAttempts.New.EnterGrnaSequenceList', {
        });

        this.searchTabPanel = Ext.create('Ext.tab.Panel', {
            layout: 'fit',
            ui: 'plain',
            frame: true,
            width: 270,
            height: 285,
            activeTab: 0,
            margin: {
                left: 10,
                right: 10
            },
            items: [
                this.exonSearch,
                this.crisprSelectBySequence
            ]
        });

        this.crisprList = Ext.create('Imits.MiAttempts.New.CrisprList', {
        });

        this.crisprpairList = Ext.create('Imits.MiAttempts.New.CrisprPairsList', {
        });

        this.crisprTabPanel = Ext.create('Ext.tab.Panel', {
            layout: 'fit',
            ui: 'plain',
            activeTab: 0,
            margin: {
                top: 0,
                bottom: 10,
                left: 10,
                right: 10
            },
            items: [
                this.crisprList,
                this.crisprpairList
            ],
            listeners: {
                tabchange: function() {
                  var exonselect = mutagensisFactorPanel.window.crisprSearch.crisprFindSelect.exonSearch.exonsList
                  if (exonselect.getSelectionModel().hasSelection()){
                      var record = exonselect.getSelectionModel().getSelection()[0];
                      exonselect.fireEvent('itemclick', exonselect, record);
                  }
                }
            }
        });


      this.add([this.searchTabPanel, this.crisprTabPanel]);
  }

});


Ext.define('Imits.MiAttempts.New.EnterGrnaSequenceList', {
  extend: 'Ext.panel.Panel',
  title: 'Search by gRNA Sequence',
  ui: 'plain',
  layout: {
    type: 'vbox',
    align: 'stretch'
  },

  performSearch: function(){
      var urlParams = {};
      urlParams['seq'] = mutagensisFactorPanel.window.crisprSearch.crisprFindSelect.crisprSelectBySequence.searchBySequenceTextField.getValue();
      mutagensisFactorPanel.window.showLoadMask();
      mutagensisFactorPanel.window.crisprSearch.crisprFindSelect.exonSearch.exonsList.getSelectionModel().clearSelections(true);
      mutagensisFactorPanel.window.crisprSearch.crisprFindSelect.crisprList.getStore().removeAll();
      mutagensisFactorPanel.window.crisprSearch.crisprFindSelect.crisprpairList.getStore().removeAll();
      mutagensisFactorPanel.window.crisprSearch.crisprFindSelect.crisprTabPanel.setActiveTab(0)
      var url = mutagensisFactorPanel.window.crisprSearch.crisprFindSelect.crisprTabPanel.getActiveTab().url_search_by_sequence;
      Ext.Ajax.request({
        method: 'GET',
        url: window.basePath + url,
        params: urlParams,
        success: function(response) {
            var data = Ext.decode(response.responseText);
            mutagensisFactorPanel.window.crisprSearch.crisprFindSelect.crisprList.getStore().loadData(data, false);
            mutagensisFactorPanel.window.hideLoadMask();
        },
        scope: this
      });
  },

  initComponent: function() {
      this.callParent();

      this.add(Ext.create('Ext.form.Label', {
          text: 'Enter 20 base gRNA sequences',
          margin: {
              top: 25,
              bottom: 10,
              left: 10,
              right: 10
          }
      }));

      this.searchBySequenceTextField = (Ext.create('Ext.form.field.TextArea', {
          name: 'grna-search-box',
          selectOnFocus: true,
          width      : 200,
          height     : 195,
          margin: {
              left: 10,
              right: 10
          },
          listeners: {
              specialkey: function(field, e) {
                  if(e.getKey() == e.TAB) {
                      mutagensisFactorPanel.window.crisprSearch.crisprFindSelect.crisprSelectBySequence.performSearch();
                  }
              },
              scope: this
          }
      })
      );

      this.add(this.searchBySequenceTextField);

      this.add(Ext.create('Ext.Button', {
        text    : 'Find Crisprs',
        margin: {
              left: 10,
              right: 10
        },
        handler : function() {
          mutagensisFactorPanel.window.crisprSearch.crisprFindSelect.crisprSelectBySequence.performSearch();
        }
      }));
  }
});


Ext.define('Imits.MiAttempts.New.SelectCrisprList', {
  extend: 'Ext.panel.Panel',
  ui: 'plain',
  title: 'Select by Exon',
  layout: {
    type: 'hbox',
    align: 'stretch'
  },

  initComponent: function() {
      this.callParent();

      this.exonsList = Ext.create('Imits.MiAttempts.New.ExonsList', {
      });

      this.add([this.exonsList]);
  }

});


Ext.define('Imits.MiAttempts.New.ExonsList', {
    extend: 'Ext.grid.Panel',
    width: 280,
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
        width: 270
    }
    ],

    initComponent: function() {
        this.callParent();

        this.addListener('itemclick', function(theView, record) {
          var urlParams = {};
          urlParams['exon_id[]'] = record.data['value'];
          mutagensisFactorPanel.window.showLoadMask();
          var url = mutagensisFactorPanel.window.crisprSearch.crisprFindSelect.crisprTabPanel.getActiveTab().url;
          Ext.Ajax.request({
            method: 'GET',
            url: window.basePath + url,
            params: urlParams,
            success: function(response) {
                var data = Ext.decode(response.responseText);
                mutagensisFactorPanel.window.crisprSearch.crisprFindSelect.crisprTabPanel.getActiveTab().getStore().loadData(data, false);
                mutagensisFactorPanel.window.hideLoadMask();
            },
            scope: this
        });
      });
    }
});

Ext.define('Imits.MiAttempts.New.CrisprList', {
    extend: 'Ext.grid.Panel',
    height: 260,
    width: 500,
    store: {
        fields: ['chr_name', 'chr_end', 'chr_start', 'seq' ],
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

    viewConfig: {
        getRowClass: function (record, index) {
            // disabled-row - custom css class for disabled (you must declare it)
            if (mutagensisFactorPanel.window.crisprSearch.crisprSelectionList.alreadySelected(record.get('seq'))) return 'disabled-row';
        }
    },

    initComponent: function() {
        this.callParent();
        this.url = '/targ_rep/wge_searches/crispr_search.json';
        this.url_search_by_sequence = '/targ_rep/wge_searches/crispr_search_by_grna_sequence.json';
        this.addListener('itemclick', function(theView, record) {
           if (mutagensisFactorPanel.window.crisprSearch.crisprSelectionList.alreadySelected(record.data['seq'])) return;
           addCrispr = {}

           addCrispr['seq'] = record.data['seq'];
           addCrispr['chr'] = record.data['chr_name'];
           addCrispr['chr_start'] = record.data['chr_start'];
           addCrispr['chr_end'] = record.data['chr_end'];

           mutagensisFactorPanel.window.crisprSearch.crisprSelectionList.createCrispr(addCrispr)
        });
    }
});

Ext.define('Imits.MiAttempts.New.CrisprPairsList', {
    extend: 'Ext.grid.Panel',
    height: 260,
    width: 510,
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

    viewConfig: {
        getRowClass: function (record, index) {
            // disabled-row - custom css class for disabled (you must declare it)
            if (mutagensisFactorPanel.window.crisprSearch.crisprSelectionList.alreadySelected(record.get('left_crispr'))) return 'disabled-row';
            if (mutagensisFactorPanel.window.crisprSearch.crisprSelectionList.alreadySelected(record.get('right_crispr'))) return 'disabled-row';
        }
    },

    initComponent: function() {
        this.callParent();
        this.url = '/targ_rep/wge_searches/crispr_pair_search.json';
        this.addListener('itemclick', function(theView, record) {
           if (mutagensisFactorPanel.window.crisprSearch.crisprSelectionList.alreadySelected(record.data['left_crispr']) || mutagensisFactorPanel.window.crisprSearch.crisprSelectionList.alreadySelected(record.data['right_crispr'])){
             return
           }
           addLeftCrispr = {}
           addRightCrispr = {}

           addLeftCrispr['seq'] = record.data['left_crispr'];
           addLeftCrispr['chr'] = record.data['left_crispr_chr'];
           addLeftCrispr['chr_start'] = record.data['left_crispr_chr_start'];
           addLeftCrispr['chr_end'] = record.data['left_crispr_chr_end'];

           addRightCrispr['seq'] = record.data['right_crispr'];
           addRightCrispr['chr'] = record.data['right_crispr_chr'];
           addRightCrispr['chr_start'] = record.data['right_crispr_chr_start'];
           addRightCrispr['chr_end'] = record.data['right_crispr_chr_end'];
           mutagensisFactorPanel.window.crisprSearch.crisprSelectionList.createCrispr([addLeftCrispr, addRightCrispr])
        });
    }
});


Ext.define('Imits.MiAttempts.New.CrisprSelectionList', {
    extend: 'Ext.grid.Panel',
    height: 160,
    margin: {
        left: 10,
        top: 25,
        right: 10,
        bottom: 10
    },
    store: {
        fields: ['chr', 'chr_end', 'chr_start', 'seq', 'grna_concentration' ],
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
    title: 'Mutagenesis Factor: Crispr Selection',
    columns: [
    {
        header: 'Sequence',
        dataIndex: 'seq',
        width: 250
    },

    {
        header: 'Chr',
        dataIndex: 'chr',
        width: 85
    },
    {
        header: 'Chr Start',
        dataIndex: 'chr_start',
        width: 150
    },
    {
        header: 'Chr End',
        dataIndex: 'chr_end',
        width: 155
    },
    {
        header: 'gRNA Concentration',
        dataIndex: 'grna_concentration',
        hidden: true,
        width: 155
    },
    {
        xtype:'actioncolumn',
        width:40,
        items: [{
            icon: '../images/icons/delete.png',
            tooltip: 'Delete',
            handler: function(grid, rowIndex, colIndex) {
                if(confirm("Remove crispr?"))
                    mutagensisFactorPanel.window.crisprSearch.crisprSelectionList.getStore().removeAt(rowIndex)
                    mutagensisFactorPanel.window.crisprSearch.crisprFindSelect.crisprList.view.refresh();
                    mutagensisFactorPanel.window.crisprSearch.crisprFindSelect.crisprpairList.view.refresh();
            }
        }]
    }
    ],

    createCrispr: function(addCrisprs) {
        mutagensisFactorPanel.window.crisprSearch.crisprSelectionList.getStore().add(addCrisprs);
        mutagensisFactorPanel.window.crisprSearch.crisprFindSelect.crisprList.view.refresh();
        mutagensisFactorPanel.window.crisprSearch.crisprFindSelect.crisprpairList.view.refresh();
    },

    alreadySelected: function(crispr) {
       var selected = false
       mutagensisFactorPanel.window.crisprSearch.crisprSelectionList.getStore().data.items.forEach(
           function(item) {
               if (crispr == item.data['seq']){
                   selected = true;
                   return false;
               }
           }
       )
       return selected
    },

    initComponent: function() {
        var self = this;
        self.callParent();
        self.url = '/targ_rep/wge_searches/crispr_search.json';
        self.seqText = Ext.create('Ext.form.field.Text', {
            id: 'seqText',
            fieldLabel: 'Sequence',
            labelAlign: 'left',
            labelWidth: 50,
            width: 250,
            hidden: false
        });
        self.chrText =  Ext.create('Ext.form.field.Text', {
            id: 'chrText',
            fieldLabel: 'Chr',
            labelAlign: 'left',
            labelWidth: 30,
            width: 80,
            hidden: false
        });
        self.chrStartText =  Ext.create('Ext.form.field.Text', {
            id: 'chrStartText',
            fieldLabel: 'Chr Start',
            labelAlign: 'left',
            labelWidth: 50,
            width: 150,
            hidden: false
        });
        self.chrEndText =  Ext.create('Ext.form.field.Text', {
            id: 'chrEndText',
            fieldLabel: 'Chr End',
            labelAlign: 'left',
            labelWidth: 50,
            width: 150,
            hidden: false
        });

        self.addDocked(Ext.create('Ext.toolbar.Toolbar', {
            dock: 'top',
            items: [
            self.seqText,
            self.chrText,
            self.chrStartText,
            self.chrEndText,
            '  ',
            {
                id: 'add_crispr_button',
                text: 'Add Crispr',
                cls:'x-btn-text-icon',
                iconCls: 'icon-add',
                grid: self,
                handler: function() {
                    var sequenceValue = self.seqText.getSubmitValue();
                    var chrValue      = self.chrText.getSubmitValue();
                    var chrStartValue = self.chrStartText.getSubmitValue();
                    var chrEndValue   = self.chrEndText.getSubmitValue();

                    if(!sequenceValue || sequenceValue && (sequenceValue.length < 23 || sequenceValue.length > 23) ) {
                        alert("You must enter a valid crispr sequence of length 23.");
                        return;
                    }

                    if(((!(sequenceValue.match(/^[ACGT]+$/i))))) {
                        alert("You must enter a valid crispr sequence containing only [ACGT].");
                        return;
                    }

                    if(!chrValue) {
                        alert("You must enter chromosome name.");
                        return;
                    }

                    if(!chrStartValue) {
                        alert("You must enter the Crisprs chromosome start.");
                        return;
                    }

                    if((!(chrStartValue.match(/^[0-9]+$/)))) {
                        alert("You must enter a number for the chromosome start.");
                        return;
                    }

                    if(!chrEndValue) {
                        alert("You must enter the Crisprs chromosome start.");
                        return;
                    }

                    if(!(chrEndValue.match(/^[0-9]+$/))) {
                        alert("You must enter a number for the chromosome end.");
                        return;
                    }

                    if (mutagensisFactorPanel.window.crisprSearch.crisprSelectionList.alreadySelected(sequenceValue)){
                        alert("Crispr already selected.");
                        return;
                    }

                    var addCrispr = {};
                    addCrispr['seq'] = sequenceValue.toUpperCase();
                    addCrispr['chr'] = chrValue;
                    addCrispr['chr_start'] = chrStartValue;
                    addCrispr['chr_end'] = chrEndValue;
                    self.createCrispr(addCrispr);

                    // reset fields after successful save.
                    self.seqText.setValue('');
                    self.chrText.setValue('');
                    self.chrStartText.setValue(0);
                    self.chrEndText.setValue(0);
                }
            }
           ]
        }));
    }
});
