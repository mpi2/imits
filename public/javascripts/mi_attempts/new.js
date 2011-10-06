Ext.namespace('Imits.MiAttempts.New');

Ext.onReady(function() {
    processRestOfForm();

    var panel = Ext.create('Imits.MiAttempts.New.EsCellSelectorForm', {
        renderTo: 'es-cell-selector'
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

    restOfForm.showIfHidden = function() {
        if(this.hidden == true) {
            this.setVisible(true, true);
            this.hidden = false;
        }
    }

    restOfForm.esCellNameField = restOfForm.child('input[name="mi_attempt[es_cell_name]"]');

    restOfForm.setEsCellDetails = function(esCellName, esCellMarkerSymbol) {
        this.esCellNameField.set({
            value: esCellName
        });
        restOfForm.esCellMarkerSymbol = esCellMarkerSymbol;
    }

    restOfForm.getEsCellName = function() {
        return this.esCellNameField.getValue();
    }

    if(restOfForm.getEsCellName() == '') {
        restOfForm.setVisibilityMode(Ext.Element.DISPLAY);
        restOfForm.setVisible(false, false);
        restOfForm.hidden = true;
    } else {
        restOfForm.hidden = false;
    }

    restOfForm.ignoreWarningsField = restOfForm.child('input[name="ignore_warnings"]');

    var esCellMarkerSymbolField = restOfForm.child('input[name="mi_attempt[es_cell_marker_symbol]"]');
    restOfForm.esCellMarkerSymbol = esCellMarkerSymbolField.getValue();
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
    height: 90,

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
        Imits.MiAttempts.New.restOfForm.setEsCellDetails(esCellName, esCellMarkerSymbol);
        Imits.MiAttempts.New.restOfForm.showIfHidden();
    },

    renderHandler: function() {
        var defaultEsCellName = Imits.MiAttempts.New.restOfForm.getEsCellName();
        if(defaultEsCellName != '') {
            this.esCellNameTextField.setValue(defaultEsCellName);
        } else {
            this.window.show();
        }

    }
});

Ext.define('Imits.MiAttempts.New.EsCellSelectorWindow', {
    extend: 'Ext.window.Window',

    title: 'Search for ES cells',
    resizable: false,
    layout: 'fit',
    closeAction: 'hide',
    width: 550,
    height: 300,
    y: 175,
    plain: true,

    showLoadMask: function() {
        this.loadMask = new Ext.LoadMask(this.tabPanel.getEl());
        this.loadMask.show();
    },

    hideLoadMask: function() {
        this.loadMask.hide();
    },

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
            url: window.basePath + '/es_cells/mart_search.json',
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
        fields: ['escell_clone', 'marker_symbol', 'pipeline', 'mutation_subtype', 'production_qc_loxp_screen'],
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
        dataIndex: 'escell_clone',
        width: 100
    },
    {
        header: 'Marker Symbol',
        dataIndex: 'marker_symbol',
        width: 90
    },
    {
        header: 'Pipeline',
        dataIndex: 'pipeline',
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
            var esCellName = record.data['escell_clone'];
            this.initialConfig.esCellSelectorForm.onEsCellNameSelected(record.data['escell_clone'], record.data['marker_symbol']);
        });
    }
});
