Ext.ns('Kermits2.newMI');

Kermits2.newMI.ClonesList = Ext.extend(Ext.ListView, {
    height: 150,
    width: 500,
    columns: [
    {
        header: 'ES Cell Clone',
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
    //autoExpandColumn: '0',
    singleSelect: true,
    style: {
        backgroundColor: 'white'
    },

    initComponent: function() {
        Kermits2.newMI.ClonesList.superclass.initComponent.call(this);

        this.cloneSelectorForm = this.initialConfig.cloneSelectorForm;

        this.addListener({
            'selectionchange': function() {
                var indices = this.getSelectedIndexes();
                if(indices.length == 0) {
                    return;
                }
                var cloneName = this.getStore().getAt(indices[0]).data['escell_clone'];
                this.cloneSelectorForm.onCloneNameSelected(cloneName);
            }
        });
    },

    onRender: function() {
        Kermits2.newMI.ClonesList.superclass.onRender.apply(this, arguments);
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
        this.clonesList.getStore().removeAll();
    },

    performSearch: function() {
        this.cloneSelectorForm.window.showLoadMask();
        var urlParams = {}
        urlParams[this.initialConfig.searchParam] = this.searchBox.getValue();
        Ext.Ajax.request({
            url: window.martSearchClonesPath + '?' + Ext.urlEncode(urlParams),
            success: function(response) {
                var data = Ext.decode(response.responseText);
                this.clonesList.getStore().loadData({'rows': data});
                this.cloneSelectorForm.window.hideLoadMask();
            },
            scope: this
        });
    },

    initComponent: function() {
        this.viewConfig = {
            forceFit: true
        };

        Kermits2.newMI.SearchTab.superclass.initComponent.call(this);

        this.cloneSelectorForm = this.initialConfig.cloneSelectorForm;

        this.add(new Ext.Panel({
            layout: 'hbox',
            unstyled: true,
            fieldLabel: this.initialConfig.searchBoxLabel,
            items: [
            {
                xtype: 'textfield',
                ref: '../searchBox',
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

        this.clonesList = new Kermits2.newMI.ClonesList({
            fieldLabel: 'Choose a clone to micro-inject',
            cloneSelectorForm: this.cloneSelectorForm
        });
        this.add(this.clonesList);
    }
});

Kermits2.newMI.CloneSelectorWindow = Ext.extend(Ext.Window, {
    title: 'Search for clones',
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

        Kermits2.newMI.CloneSelectorWindow.superclass.initComponent.call(this);

        this.cloneSearchTab = new Kermits2.newMI.SearchTab({
            cloneSelectorForm: this.initialConfig.cloneSelectorForm,
            title: 'Search by clone name',
            searchBoxLabel: 'Enter clone name',
            searchParam: 'clone_name'
        });

        this.markerSymbolSearchTab = new Kermits2.newMI.SearchTab({
            cloneSelectorForm: this.initialConfig.cloneSelectorForm,
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
            this.cloneSearchTab
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

Kermits2.newMI.CloneSelectorForm = Ext.extend(Ext.Panel, {
    layout: 'form',
    border: false,
    unstyled: true,
    labelAlign: 'top',

    initComponent: function() {
        this.viewConfig = {
            forceFit: true
        };

        Kermits2.newMI.CloneSelectorForm.superclass.initComponent.call(this);

        this.add(new Ext.Panel({
            layout: 'hbox',
            unstyled: true,
            fieldLabel: 'Select a clone',
            border: false,
            items: [
            {
                ref: '../cloneNameTextField',
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

        this.window = new Kermits2.newMI.CloneSelectorWindow({
            cloneSelectorForm: this
        });
    },

    onRender: function() {
        Kermits2.newMI.CloneSelectorForm.superclass.onRender.apply(this, arguments);
        this.window.show();
    },

    onCloneNameSelected: function(cloneName) {
        this.cloneNameTextField.setValue(cloneName);
        this.window.hide();
        Kermits2.newMI.restOfForm.setCloneName(cloneName);
        Kermits2.newMI.restOfForm.showIfHidden();
    }
});

function processRestOfForm() {
    Kermits2.newMI.restOfForm = Ext.get('rest-of-form');
    Kermits2.newMI.restOfForm.hide(false);
    Kermits2.newMI.restOfForm.hidden = true;
    Kermits2.newMI.restOfForm.showIfHidden = function() {
        if(this.hidden == true) {
            this.show(true);
            this.hidden = false;
        }
    }
    Kermits2.newMI.restOfForm.setCloneName = function(cloneName) {
        var cloneNameField = this.child('input[name="mi_attempt[clone_name]"]');
        cloneNameField.set({
            value: cloneName
        });
    }
}

Ext.onReady(function() {
    processRestOfForm();

    var panel = new Kermits2.newMI.CloneSelectorForm({
        renderTo: 'clone-selector'
    });
});
