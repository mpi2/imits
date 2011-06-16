Kermits2.ClonesList = Ext.extend(Ext.ListView, {
    height: 100,
    width: 180,
    store: new Ext.data.ArrayStore({
        data: [],
        fields: ['clone_name']
    }),
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
    listeners: {
        selectionchange: {
            fn: function(listView) {
                var indices = listView.getSelectedIndexes();
                if(indices.length == 0) {
                    return;
                }
                var cloneName = listView.getStore().getAt(indices[0]).data['clone_name'];
                listView.initialConfig.cloneSelectorForm.cloneNameTextField.setValue(cloneName);
                Kermits2.restOfForm.setCloneName(cloneName);
                listView.initialConfig.cloneSelectorForm.window.hideAfterSelection();
                Kermits2.restOfForm.showIfHidden();
            },
            scope: this
        }
    }
});

Kermits2.CloneSearchTab = Ext.extend(Ext.Panel, {
    layout: 'form',
    unstyled: true,
    title: 'Search by clone name',

    resetForm: function() {
        this.cloneNameSearchBox.setValue('');
        this.clonesList.getStore().removeAll();
    },

    performSearch: function() {
        this.cloneSelectorForm.window.showLoadMask();
        Ext.Ajax.request({
            url: '/clones/mart_search.json?' + Ext.urlEncode({
                'clone_name': this.cloneNameSearchBox.getValue()
            }),
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

        Kermits2.CloneSearchTab.superclass.initComponent.call(this);

        this.cloneSelectorForm = this.initialConfig.cloneSelectorForm;

        this.add(new Ext.Panel({
            layout: 'hbox',
            unstyled: true,
            fieldLabel: 'Enter clone name',
            items: [
            {
                xtype: 'textfield',
                ref: '../cloneNameSearchBox',
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

        this.add(new Kermits2.ClonesList({
            ref: 'clonesList',
            fieldLabel: 'Choose a clone to micro inject',
            cloneSelectorForm: this.cloneSelectorForm
        }));
    }
});

Kermits2.CloneSelectorWindow = Ext.extend(Ext.Window, {
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

        Kermits2.CloneSelectorWindow.superclass.initComponent.call(this);

        this.cloneSearchTab = new Kermits2.CloneSearchTab({
            cloneSelectorForm: this.initialConfig.cloneSelectorForm
        });

        this.centerPanel = new Ext.TabPanel({
            ref: 'centerPanel',
            padding: 10,
            unstyled: true,
            defaults: {unstyled: true},
            activeTab: 0,
            items: [
            this.cloneSearchTab,
            {
                title: 'Search by gene symbol',
                items: {
                    xtype: 'textfield'
                }
            }
            ]
        });

        this.add(this.centerPanel);
    },

    hideAfterSelection: function() {
        this.cloneSearchTab.resetForm();
        this.hide();
    }
});

Kermits2.CloneSelectorForm = Ext.extend(Ext.Panel, {
    layout: 'form',
    border: false,
    unstyled: true,

    initComponent: function() {
        this.viewConfig = {
            forceFit: true
        };

        Kermits2.CloneSelectorForm.superclass.initComponent.call(this);

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

        this.window = new Kermits2.CloneSelectorWindow({
            cloneSelectorForm: this
        });
    },

    onRender: function() {
        Kermits2.CloneSelectorForm.superclass.onRender.apply(this, arguments);
        this.window.show();
    }
});

function processRestOfForm() {
    Kermits2.restOfForm = Ext.get('rest-of-form');
    Kermits2.restOfForm.hide(false);
    Kermits2.restOfForm.hidden = true;
    Kermits2.restOfForm.showIfHidden = function() {
        if(this.hidden == true) {
            this.show(true);
            this.hidden = false;
        }
    }
    Kermits2.restOfForm.setCloneName = function(cloneName) {
        var cloneNameField = this.child('input[name="mi_attempt[clone_name]"]');
        cloneNameField.set({
            value: cloneName
        });
    }
}

function onMiAttemptsNew() {
    processRestOfForm();

    var panel = new Kermits2.CloneSelectorForm({
        renderTo: 'clone-selector'
    });
}

Ext.onReady(function() {
    onMiAttemptsNew();
});
