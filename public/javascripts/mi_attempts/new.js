Kermits2.CloneSelectorWindow = Ext.extend(Ext.Window, {
    title: 'Search for clones',
    resizable: false,
    layout: 'fit',
    closeAction: 'hide',
    width: 400,
    height: 200,
    plain: true,

    initComponent: function() {
        this.viewConfig = {
            forceFit: true
        };

        Kermits2.CloneSelectorWindow.superclass.initComponent.call(this);

        this.cloneSelectorForm = this.initialConfig.cloneSelectorForm;

        this.cloneSearchTab = new Ext.Panel({
            layout: 'form',
            unstyled: true,
            title: 'Search by clone name',

            items: [
            {
                xtype: 'panel',
                layout: 'hbox',
                unstyled: true,
                fieldLabel: 'Enter clone name',
                items: [
                {
                    xtype: 'textfield',
                    ref: '../cloneNameField'
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
                            fn: function() {
                                this.cloneSearchTab.clonesList.getStore().loadData([
                                    ['EPD0127_4_E01']
                                    ]);
                            },
                            scope: this
                        }
                    }
                }
                ]
            },
            {
                xtype: 'listview',
                fieldLabel: 'Choose a clone to micro inject',
                ref: 'clonesList',
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
                            this.cloneSelectorForm.cloneNameTextField.setValue(cloneName);
                            Kermits2.restOfForm.setCloneName(cloneName);
                            this.hideAfterSelection();
                            Kermits2.restOfForm.showIfHidden();
                        },
                        scope: this
                    }
                }
            }
            ]
        });

        this.centerPanel = new Ext.TabPanel({
            disablePanel: function() {
                console.log(this);
            },
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
        this.cloneSearchTab.cloneNameField.setValue('');
        this.cloneSearchTab.clonesList.getStore().removeAll();
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

        var cloneButton = new Ext.Button();

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
                            this.cloneSelectorWindow.show();
                        },
                        scope: this
                    }
                }
            }
            ]
        }));

        this.cloneSelectorWindow = new Kermits2.CloneSelectorWindow({
            cloneSelectorForm: this
        });
    },

    onRender: function() {
        Kermits2.CloneSelectorForm.superclass.onRender.apply(this, arguments);
        this.cloneSelectorWindow.show();
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
