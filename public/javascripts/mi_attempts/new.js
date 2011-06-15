function oldOnMiAttemptsNew() {
    var form = Ext.select('form.new.mi-attempt', true).first();
    if(! form) {return;}
    form.dom.onsubmit = function() {return false;};

    var restOfForm = Ext.get('rest-of-form');
    restOfForm.hide(false);

    var genes = [];
    Ext.each(Kermits2.propertyNames(window.allClonesPartitionedByMarkerSymbol), function(gene) {
        if(gene == '') {
            genes.push([gene, '[All]']);
        } else {
            genes.push([gene, gene]);
        }
    });

    var geneCombo = new Ext.form.ComboBox({
        forceSelection: true,
        triggerAction: 'all',
        mode: 'local',
        lazyRender: true,
        store: genes,
        autoSelect: true,
        id: 'gene-combo'
    });

    geneCombo.onSelectListener = function(combo, record) {
        var gene = record.data[combo.valueField];
        cloneCombo.loadDataForGene(gene);
    }

    geneCombo.addListener('select', geneCombo.onSelectListener);

    var cloneCombo = new Ext.form.ComboBox({
        hiddenName: 'mi_attempt[clone_id]',
        hiddenId: 'mi_attempt_clone_id',
        lazyRender: true,
        forceSelection: true,
        triggerAction: 'all',
        mode: 'local',
        store: new Ext.data.JsonStore({
            root: 'rows',
            fields: ['id', 'clone_name']
        }),
        valueField: 'id',
        displayField: 'clone_name'
    });
    cloneCombo.loadDataForGene = function(gene) {
        this.store.loadData({
            rows: window.allClonesPartitionedByMarkerSymbol[gene]
        });
        this.setValue('');
        restOfForm.hide(false);
        form.dom.onsubmit = function() {return false;}
    }

    cloneCombo.addListener('select', function() {
        restOfForm.show(true);
        form.dom.onsubmit = null;
    });

    cloneCombo.loadDataForGene('');

    var clonePanel = new Ext.Panel({
        layout: 'vbox',
        renderTo: 'mi_attempt_clone_id_combo',
        height: 90,
        border: false,
        items: [
        {
            xtype: 'panel',
            layout: 'vbox',
            height: 40,
            border: false,
            margins: '0 0 10 0',
            items: [
            {
                xtype: 'label',
                text: 'Marker symbol'
            },
            geneCombo
            ]
        },
        {
            xtype: 'panel',
            layout: 'vbox',
            height: 40,
            border: false,
            items: [
            {
                xtype: 'label',
                text: 'ES cell clone name',
                forId: 'mi_attempt_clone_id'
            },
            cloneCombo
            ]
        }
        ]
    });

    geneCombo.getEl().dom.value = '[All]';
}

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
            baseCls: 'x-plain',
            title: 'Search by clone name',

            items: [
            {
                xtype: 'panel',
                layout: 'hbox',
                baseCls: 'x-plain',
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

                            this.hideAfterSelection();
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
            baseCls: 'x-plain',
            defaults: {baseCls: 'x-plain'},
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
        Kermits2.restOfForm.showIfHidden();
    }
});

Kermits2.CloneSelectorForm = Ext.extend(Ext.Panel, {
    layout: 'form',
    border: false,
    baseCls: 'x-plain',

    initComponent: function() {
        this.viewConfig = {
            forceFit: true
        };

        Kermits2.CloneSelectorForm.superclass.initComponent.call(this);

        var cloneButton = new Ext.Button();

        this.add(new Ext.Panel({
            layout: 'hbox',
            baseCls: 'x-plain',
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

    onRender: function(container) {
        Kermits2.CloneSelectorForm.superclass.onRender.apply(this, arguments);
        this.cloneSelectorWindow.show();
    }
});


function onMiAttemptsNew() {
    var form = Ext.select('form.new.mi-attempt', true).first();
    if(! form) {return;}
    form.dom.onsubmit = function() {return false;};

    Kermits2.restOfForm = Ext.get('rest-of-form');
    Kermits2.restOfForm.hide(false);
    Kermits2.restOfForm.hidden = true;
    Kermits2.restOfForm.showIfHidden = function() {
        console.log(this);
        if(this.hidden == true) {
            this.show(true);
            this.hidden = false;
        }
    }

    var panel = new Kermits2.CloneSelectorForm({
        renderTo: 'clone-selector'
    });
}

Ext.onReady(function() {
    onMiAttemptsNew();
});
