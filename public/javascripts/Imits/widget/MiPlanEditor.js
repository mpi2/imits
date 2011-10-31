Ext.define('Imits.widget.MiPlanEditor', {
    extend: 'Imits.widget.Window',

    requires: [
    'Imits.model.MiPlan'
    ],

    title: 'Change Expression of Interest to Micro-Inject',
    resizable: false,
    layout: 'fit',
    closeAction: 'hide',

    constructor: function(config) {
        if(Ext.isIE7 || Ext.isIE8) {
            config.width = 400;
        }
        return this.callParent([config]);
    },

    initComponent: function() {
        var editor = this;
        this.callParent();

        this.form = Ext.create('Ext.form.Panel', {
            ui: 'plain',
            margin: '0 0 10 0',
            width: 350,

            layout: 'anchor',
            defaults: {
                anchor: '100%'
            },

            items: [
            {
                id: 'marker_symbol',
                xtype: 'textfield',
                fieldLabel: 'Gene marker symbol',
                name: 'marker_symbol',
                readOnly: true
            },
            {
                id: 'consortium_name',
                xtype: 'textfield',
                fieldLabel: 'Consortium',
                name: 'consortium_name',
                readOnly: true
            },
            {
                id: 'production_centre_name',
                xtype: 'simplecombo',
                fieldLabel: 'Production Centre',
                name: 'production_centre_name',
                storeOptionsAreSpecial: true,
                store: window.CENTRE_COMBO_OPTS
            },
            {
                id: 'status',
                xtype: 'textfield',
                fieldLabel: 'Status',
                name: 'status',
                readOnly: true
            },
            {
                id: 'priority',
                xtype: 'simplecombo',
                fieldLabel: 'Priority',
                name: 'priority',
                store: window.PRIORITY_COMBO_OPTS
            },
            {
                id: 'number_of_es_cells_starting_qc',
                xtype: 'simplenumberfield',
                fieldLabel: '# of ES Cells starting QC',
                name: 'number_of_es_cells_starting_qc'
            }
            ],

            buttons: [
            {
                id: 'update-button',
                text: '<strong>Update</strong>',
                handler: function(button) {
                    button.disable();
                    editor.updateAndHide(function() {button.enable();});
                }
            },
            {
                text: 'Cancel',
                handler: function() {
                    editor.hide();
                }
            }
            ]
        });

        var deleteContainer = Ext.create('Ext.panel.Panel', {
            ui: 'plain',
            layout: {
                type: 'hbox',
                align: 'stretchmax'
            },
            margin: '0 0 10 0',
            items: [
            {
                xtype: 'label',
                text: "Delete interest?",
                cls: 'x-form-item-label',
                margin: '0 5 0 0'
            },
            {
                xtype: 'button',
                id: 'delete-button',
                text: 'Delete',
                width: 60,
                handler: function(button) {
                    button.hide();
                    deleteContainer.getComponent('delete-confirmation-button').show();
                }
            },
            {
                xtype: 'button',
                id: 'delete-confirmation-button',
                text: 'Are you sure?',
                width: 100,
                hidden: true,
                handler: function(button) {
                    editor.setLoading(true);
                    editor.miPlan.destroy({
                        success: function() {
                            editor.setLoading(false);
                            editor.hide();
                        }
                    });
                    button.hide();
                    deleteContainer.getComponent('delete-button').show();
                }
            }
            ]
        });

        this.add(Ext.create('Ext.panel.Panel', {
            height: 300,
            ui: 'plain',
            layout: {
                type: 'vbox',
                align: 'stretchmax'
            },
            padding: 15,
            items: [
            this.form,
            deleteContainer
            ]
        }));

        this.fields = this.form.items.keys;
        this.updateableFields = this.form.items.filterBy(function (i) {
            return i.readOnly != true;
        }).keys;
        console.log([this.fields, this.updateableFields]);
    },

    edit: function(miPlanId) {
        var editor = this;

        Imits.model.MiPlan.load(miPlanId, {
            success: function(miPlan) {
                editor.miPlan = miPlan;
                Ext.each(editor.fields, function(attr) {
                        var component = editor.form.getComponent(attr);
                        if(component) {
                            component.setValue(editor.miPlan.get(attr));
                        }
                    });
                editor.show();
            }
        });
    },

    updateAndHide: function(callbackOnceHidden) {
        var editor = this;
        Ext.each(this.updateableFields, function(attr) {
                var component = editor.form.getComponent(attr);
                if(component) {
                    editor.miPlan.set(attr, component.getValue());
                }
            });

        editor.miPlan.save({
            success: function() {
                editor.hide();
                callbackOnceHidden.call();
            },

            failure: function() {
                callbackOnceHidden.call();
            }
        });
    }
});
