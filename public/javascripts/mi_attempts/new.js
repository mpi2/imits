Ext.ns('Kermits2.newMI');

Kermits2.newMI.ClonesList = Ext.extend(Ext.ListView, {
    height: 100,
    width: 180,
    columns: [
    {
        sortable: true,
        dataIndex: 'clone_name'
    }
    ],
    autoExpandColumn: '0',
    singleSelect: true,
    hideHeaders: true,
    style: {
        backgroundColor: 'white'
    },

    initComponent: function() {
        Kermits2.newMI.ClonesList.superclass.initComponent.call(this);

        this.cloneSelectorForm = this.initialConfig.cloneSelectorForm;
    },

    onRender: function() {
        Kermits2.newMI.ClonesList.superclass.onRender.apply(this, arguments);

        this.bindStore(new Ext.data.ArrayStore({
            data: [],
            fields: ['clone_name']
        }));
    },

    listeners: {
        selectionchange: {
            fn: function(listView) {
                var indices = listView.getSelectedIndexes();
                if(indices.length == 0) {
                    return;
                }
                var cloneName = listView.getStore().getAt(indices[0]).data['clone_name'];
                listView.cloneSelectorForm.cloneNameTextField.setValue(cloneName);
                Kermits2.newMI.restOfForm.setCloneName(cloneName);
                listView.cloneSelectorForm.window.hideAfterSelection();
                Kermits2.newMI.restOfForm.showIfHidden();
            },
            scope: this
        }
    }
});

Kermits2.newMI.SearchTab = Ext.extend(Ext.Panel, {
    layout: 'form',
    unstyled: true,
    labelWidth: 125,

    resetForm: function() {
        this.searchBox.setValue('');
        this.clonesList.getStore().removeAll();
    },

    performSearch: function() {
        this.cloneSelectorForm.window.showLoadMask();
        var urlParams = {}
        urlParams[this.initialConfig.searchParam] = this.searchBox.getValue();
        Ext.Ajax.request({
            url: '/clones/mart_search.json?' + Ext.urlEncode(urlParams),
            success: function(response) {
                var data = Ext.decode(response.responseText);
                var storeData = [];
                Ext.each(data, function(i) {
                    storeData.push( [ i['escell_clone'] ] );
                });
                this.clonesList.getStore().loadData(storeData);
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

        this.add(new Kermits2.newMI.ClonesList({
            ref: 'clonesList',
            fieldLabel: 'Choose a clone to micro-inject',
            cloneSelectorForm: this.cloneSelectorForm
        }));
    }
});

Kermits2.newMI.CloneSelectorWindow = Ext.extend(Ext.Window, {
    title: 'Search for clones',
    resizable: false,
    layout: 'fit',
    closeAction: 'hide',
    width: 400,
    height: 200,
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
    },

    hideAfterSelection: function() {
        this.cloneSearchTab.resetForm();
        this.hide();
    }
});

Kermits2.newMI.CloneSelectorForm = Ext.extend(Ext.Panel, {
    layout: 'form',
    border: false,
    unstyled: true,

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
