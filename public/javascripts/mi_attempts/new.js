Ext.namespace('Kermits2.newMI');

Ext.onReady(function() {
    processRestOfForm();

    var panel = Ext.create('Kermits2.newMI.EsCellSelectorForm', {
        renderTo: 'es-cell-selector'
    });
});

function processRestOfForm() {
    Kermits2.newMI.restOfForm = Ext.get('rest-of-form');

    Kermits2.newMI.restOfForm.showIfHidden = function() {
        if(this.hidden == true) {
            this.setVisible(true, true);
            this.hidden = false;
        }
    }

    Kermits2.newMI.restOfForm.setEsCellName = function(esCellName) {
        var esCellNameField = this.child('input[name="mi_attempt[es_cell_name]"]');
        esCellNameField.set({
            value: esCellName
        });
    }

    Kermits2.newMI.restOfForm.getEsCellName = function() {
        var esCellNameField = this.child('input[name="mi_attempt[es_cell_name]"]');
        return esCellNameField.getValue();
    }

    if(Kermits2.newMI.restOfForm.getEsCellName() == '') {
        Kermits2.newMI.restOfForm.setVisibilityMode(Ext.Element.DISPLAY);
        Kermits2.newMI.restOfForm.setVisible(false, false);
        Kermits2.newMI.restOfForm.hidden = true;
    } else {
        Kermits2.newMI.restOfForm.hidden = false;
    }

}

Ext.define('Kermits2.newMI.EsCellSelectorForm', {
    extend: 'Ext.panel.Panel',
    layout: {
        type: 'vbox',
        align: 'stretch'
    },
    ui: 'plain',
    width: 300,
    height: 60, // TODO Should be 40, but button is too high

    initComponent: function() {
        this.callParent();

        this.add(Ext.create('Ext.form.Label', {
            text: 'Select an ES cell clone'
        }));

        this.esCellNameTextField = Ext.create('Ext.form.field.Text', {
            disabled: true,
            style: {color: 'black'}
        });

        this.add(Ext.create('Ext.panel.Panel', {
            layout: {
                type: 'hbox',
                align: 'stretchmax'
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

        this.window = Ext.create('Kermits2.newMI.EsCellSelectorWindow', {
            esCellSelectorForm: this
        });

        this.window.show();
    },

    onEsCellNameSelected: function(esCellName) {
        this.esCellNameTextField.setValue(esCellName);
        this.window.hide();
        Kermits2.newMI.restOfForm.setEsCellName(esCellName);
        Kermits2.newMI.restOfForm.showIfHidden();
    }
});

Ext.define('Kermits2.newMI.EsCellSelectorWindow', {
    extend: 'Ext.window.Window',

    title: 'Search for ES cells',
    resizable: false,
    layout: 'fit',
    closeAction: 'hide',
    width: 550,
    height: 300,
    y: 175,
    plain: true,

    initComponent: function() {
        this.callParent();

        this.esCellSearchTab = Ext.create('Kermits2.newMI.SearchTab', {
            esCellSelectorForm: this.initialConfig.esCellSelectorForm,
            title: 'Search by ES cell name',
            searchBoxLabel: 'Enter ES cell name',
            searchParam: 'es_cell_name'
        });

        this.markerSymbolSearchTab = new Kermits2.newMI.SearchTab({
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
            console.log('tab changed');
        // newTab.searchBox.focus();
        });

        this.addListener('show', function(theWindow) {
            console.log('window shown');
        // theWindow.centerPanel.getActiveTab().searchBox.focus(true, 50);
        });

        this.add(this.tabPanel);
    }

});

Ext.define('Kermits2.newMI.SearchTab', {
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
        console.log('Performing search');
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
                bottom: 0,
                left: 0,
                right: 0
            }
        }));

        this.add(Ext.create('Ext.panel.Panel', {
            layout: {
                type: 'hbox',
                align: 'stretchmax'
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
                bottom: 0,
                left: 0,
                right: 0
            }
        }));

        this.esCellsList = Ext.create('Kermits2.newMI.EsCellsList', {
            esCellSelectorForm: this.initialConfig.esCellSelectorForm
        });
        this.add(this.esCellsList);
    }
});

Ext.define('Kermits2.newMI.EsCellsList', {
    extend: 'Ext.grid.Panel',
    height: 150,
    store: Ext.create('Ext.data.Store', {
        fields: ['escell_clone', 'marker_symbol', 'pipeline', 'mutation_subtype', 'production_qc_loxp_screen'],
        data: {
            'rows': [
            {
                escell_clone: 'EPD0127_4_E01',
                marker_symbol: 'Trafd1',
                pipeline: 'EUCOMM',
                mutation_subtype: 'conditional_ready',
                production_qc_loxp_screen: 'pass'
            },
            {
                escell_clone: 'EPD0127_4_E04',
                marker_symbol: 'Trafd1',
                pipeline: 'EUCOMM',
                mutation_subtype: 'targeted_non_conditional',
                production_qc_loxp_screen: 'not confirmed'
            },
            {
                escell_clone: 'EPD0127_4_F01',
                marker_symbol: 'Trafd1',
                pipeline: 'EUCOMM',
                mutation_subtype: 'conditional_ready',
                production_qc_loxp_screen: 'pass'
            }

            ]
        },
        proxy: {
            type: 'memory',
            reader: {
                type: 'json',
                root: 'rows'
            }
        }
    }),

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

/*
Kermits2.newMI.EsCellsList = Ext.extend(Ext.ListView, {
    height: 150,
    width: 500,
    columns: [
    {
        header: 'ES Cell',
        dataIndex: 'escell_clone',
        width: .21
    },
    {
        header: 'Marker Symbol',
        dataIndex: 'marker_symbol',
        width: .17
    },
    {
        header: 'Pipeline',
        dataIndex: 'pipeline',
        width: .15
    },
    {
        header: 'Mutation Subtype',
        dataIndex: 'mutation_subtype'
    },
    {
        header: 'LoxP Screen',
        dataIndex: 'production_qc_loxp_screen',
        width: .17
    }
    ],
    singleSelect: true,
    style: {
        backgroundColor: 'white'
    },

    initComponent: function() {
        Kermits2.newMI.EsCellsList.superclass.initComponent.call(this);

        this.esCellSelectorForm = this.initialConfig.esCellSelectorForm;

        this.addListener({
            'selectionchange': function() {
                var indices = this.getSelectedIndexes();
                if(indices.length == 0) {
                    return;
                }
                var esCellName = this.getStore().getAt(indices[0]).data['escell_clone'];
                this.esCellSelectorForm.onEsCellNameSelected(esCellName);
            }
        });
    },

    onRender: function() {
        Kermits2.newMI.EsCellsList.superclass.onRender.apply(this, arguments);
        this.bindStore(new Ext.data.JsonStore({
            root: 'rows',
            fields: ['escell_clone', 'marker_symbol', 'pipeline', 'mutation_subtype', 'production_qc_loxp_screen']
        }));
    }
});

Kermits2.newMI.SearchTab = Ext.extend(Ext.Panel, {
    layout: 'form',
    unstyled: true,
    labelAlign: 'top',

    resetForm: function() {
        this.searchBox.setValue('');
        this.esCellsList.getStore().removeAll();
    },

    performSearch: function() {
        this.esCellSelectorForm.window.showLoadMask();
        var urlParams = {}
        urlParams[this.initialConfig.searchParam] = this.searchBox.getValue();
        Ext.Ajax.request({
            url: window.martSearchEsCellsPath + '?' + Ext.urlEncode(urlParams),
            success: function(response) {
                var data = Ext.decode(response.responseText);
                this.esCellsList.getStore().loadData({'rows': data});
                this.esCellSelectorForm.window.hideLoadMask();
            },
            scope: this
        });
    },

    initComponent: function() {
        this.viewConfig = {
            forceFit: true
        };

        Kermits2.newMI.SearchTab.superclass.initComponent.call(this);

        this.esCellSelectorForm = this.initialConfig.esCellSelectorForm;

        this.add(new Ext.Panel({
            layout: 'hbox',
            unstyled: true,
            fieldLabel: this.initialConfig.searchBoxLabel,
            items: [
            {
                xtype: 'textfield',
                ref: '../searchBox',
                id: this.initialConfig.searchParam + '-search-box',
                selectOnFocus: true,
                listeners: {
                    specialkey: {
                        fn: function(field, e) {
                            if(e.getKey() == e.ENTER) {
                                this.performSearch();
                            }
                        },
                        scope: this
                    }
                }
            },
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

        this.esCellsList = new Kermits2.newMI.EsCellsList({
            fieldLabel: 'Choose an ES cell clone to micro-inject',
            esCellSelectorForm: this.esCellSelectorForm
        });
        this.add(this.esCellsList);
    }
});

Kermits2.newMI.EsCellSelectorWindow = Ext.extend(Ext.Window, {
    title: 'Search for ES cells',
    resizable: false,
    layout: 'fit',
    closeAction: 'hide',
    width: 550,
    height: 300,
    y: 175,
    plain: true,

    showLoadMask: function() {
        this.loadMask = new Ext.LoadMask(this.centerPanel.getEl(), {removeMask: true});
        this.loadMask.show();
    },

    hideLoadMask: function() {
        this.loadMask.hide();
    },

    initComponent: function() {
        this.viewConfig = {
            forceFit: true
        };

        Kermits2.newMI.EsCellSelectorWindow.superclass.initComponent.call(this);

        this.esCellSearchTab = new Kermits2.newMI.SearchTab({
            esCellSelectorForm: this.initialConfig.esCellSelectorForm,
            title: 'Search by ES cell name',
            searchBoxLabel: 'Enter ES cell name',
            searchParam: 'es_cell_name'
        });

        this.markerSymbolSearchTab = new Kermits2.newMI.SearchTab({
            esCellSelectorForm: this.initialConfig.esCellSelectorForm,
            title: 'Search by marker symbol',
            searchBoxLabel: 'Enter marker symbol',
            searchParam: 'marker_symbol'
        });

        this.centerPanel = new Ext.TabPanel({
            ref: 'centerPanel',
            padding: 10,
            unstyled: true,
            defaults: {unstyled: true},
            activeTab: 0,
            items: [
            this.markerSymbolSearchTab,
            this.esCellSearchTab
            ]
        });

        this.centerPanel.addListener('tabchange', function(tabPanel, newTab) {
            newTab.searchBox.focus();
        });

        this.addListener('show', function(theWindow) {
            theWindow.centerPanel.getActiveTab().searchBox.focus(true, 50);
        });

        this.add(this.centerPanel);
    }

});

Kermits2.newMI.EsCellSelectorForm = Ext.extend(Ext.Panel, {
    layout: 'form',
    border: false,
    unstyled: true,
    labelAlign: 'top',

    initComponent: function() {
        this.viewConfig = {
            forceFit: true
        };

        Kermits2.newMI.EsCellSelectorForm.superclass.initComponent.call(this);

        this.add(new Ext.Panel({
            layout: 'hbox',
            unstyled: true,
            fieldLabel: 'Select an ES cell clone',
            border: false,
            items: [
            {
                ref: '../esCellNameTextField',
                xtype: 'textfield',
                disabled: true,
                style: {
                    color: 'black'
                }
            },
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
                    click: {
                        fn: function() {
                            this.window.show();
                        },
                        scope: this
                    }
                }
            }
            ]
        }));

        this.window = new Kermits2.newMI.EsCellSelectorWindow({
            esCellSelectorForm: this
        });
    },

    onRender: function() {
        Kermits2.newMI.EsCellSelectorForm.superclass.onRender.apply(this, arguments);

        var defaultEsCellName = Kermits2.newMI.restOfForm.getEsCellName();
        if(defaultEsCellName != '') {
            this.esCellNameTextField.setValue(defaultEsCellName);
        } else {
            this.window.show();
        }
    },

    onEsCellNameSelected: function(esCellName) {
        this.esCellNameTextField.setValue(esCellName);
        this.window.hide();
        Kermits2.newMI.restOfForm.setEsCellName(esCellName);
        Kermits2.newMI.restOfForm.showIfHidden();
    }
});

function processRestOfForm() {
    Kermits2.newMI.restOfForm = Ext.get('rest-of-form');

    Kermits2.newMI.restOfForm.showIfHidden = function() {
        if(this.hidden == true) {
            this.show(true);
            this.hidden = false;
        }
    }

    Kermits2.newMI.restOfForm.setEsCellName = function(esCellName) {
        var esCellNameField = this.child('input[name="mi_attempt[es_cell_name]"]');
        esCellNameField.set({
            value: esCellName
        });
    }

    Kermits2.newMI.restOfForm.getEsCellName = function() {
        var esCellNameField = this.child('input[name="mi_attempt[es_cell_name]"]');
        return esCellNameField.getValue();
    }

    if(Kermits2.newMI.restOfForm.getEsCellName() == '') {
        Kermits2.newMI.restOfForm.hide(false);
        Kermits2.newMI.restOfForm.hidden = true;
    } else {
        Kermits2.newMI.restOfForm.hidden = false;
    }

}

Ext.onReady(function() {
    processRestOfForm();

    var panel = new Kermits2.newMI.EsCellSelectorForm({
        renderTo: 'es-cell-selector'
    });
});
*/
