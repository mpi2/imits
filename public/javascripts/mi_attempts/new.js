Ext.namespace('Imits.MiAttempts.New');

Ext.onReady(function() {
    processRestOfForm();

    var panel = Ext.create('Imits.MiAttempts.New.EsCellSelectorForm', {
        renderTo: 'es-cell-selector'
    });
});

function processRestOfForm() {
    Imits.MiAttempts.New.restOfForm = Ext.get('rest-of-form');

    Imits.MiAttempts.New.restOfForm.showIfHidden = function() {
        if(this.hidden == true) {
            this.setVisible(true, true);
            this.hidden = false;
        }
    }

    Imits.MiAttempts.New.restOfForm.setEsCellName = function(esCellName) {
        var esCellNameField = this.child('input[name="mi_attempt[es_cell_name]"]');
        esCellNameField.set({
            value: esCellName
        });
    }

    Imits.MiAttempts.New.restOfForm.getEsCellName = function() {
        var esCellNameField = this.child('input[name="mi_attempt[es_cell_name]"]');
        return esCellNameField.getValue();
    }

    if(Imits.MiAttempts.New.restOfForm.getEsCellName() == '') {
        Imits.MiAttempts.New.restOfForm.setVisibilityMode(Ext.Element.DISPLAY);
        Imits.MiAttempts.New.restOfForm.setVisible(false, false);
        Imits.MiAttempts.New.restOfForm.hidden = true;
    } else {
        Imits.MiAttempts.New.restOfForm.hidden = false;
    }

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

        this.add(Ext.create('Ext.form.Label', {
            text: 'Select an ES cell clone',
            margins: '0 0 5 0'
        }));

        this.esCellNameTextField = Ext.create('Ext.form.field.Text', {
            disabled: true,
            style: {color: 'black'}
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

    onEsCellNameSelected: function(esCellName) {
        this.esCellNameTextField.setValue(esCellName);
        this.window.hide();
        Imits.MiAttempts.New.restOfForm.setEsCellName(esCellName);
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
            id: this.initialConfig.searchParam + '-search-box',
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
            this.initialConfig.esCellSelectorForm.onEsCellNameSelected(esCellName);
        });
    }
});
