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
            config.width = 300;
        }
        return this.callParent([config]);
    },

    initComponent: function() {
        var editor = this;
        this.callParent();

        this.form = Ext.create('Ext.form.Panel', {
            ui: 'plain',
            margin: '0 0 10 0',

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
                text: 'Update',
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
            layout: 'hbox',
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
                    editor.setLoading(true);
                    editor.miPlan.destroy({
                        success: function() {
                            editor.setLoading(false);
                            editor.hide();
                        }
                    });
                }
            }
            ]
        });

        this.statusBar = Ext.create('Ext.panel.Panel', {
            ui: 'plain',
            html: window.NO_BREAK_SPACE
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
            deleteContainer,
            this.statusBar
            ]
        }));
    },

    edit: function(miPlanId) {
        var editor = this;

        Imits.model.MiPlan.load(miPlanId, {
            success: function(miPlan) {
                editor.miPlan = miPlan;
                Ext.each([
                    'marker_symbol',
                    'consortium_name',
                    'production_centre_name',
                    'status',
                    'priority',
                    'number_of_es_cells_starting_qc'
                    ], function(attr) {
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
        Ext.each([
            'production_centre_name',
            'priority',
            'number_of_es_cells_starting_qc'
            ], function(attr) {
                var component = editor.form.getComponent(attr);
                if(component) {
                    editor.miPlan.set(attr, component.getValue());
                }
            });

        editor.miPlan.save({
            success: function() {
                editor.hide();
                callback.call();
            }
        });
    }
});
