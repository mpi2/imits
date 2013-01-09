Ext.define('Imits.widget.MiPlanEditor', {
    extend: 'Imits.widget.Window',

    requires: [
    'Imits.model.MiPlan',
    'Imits.widget.SimpleCombo',
    'Imits.widget.SimpleCheckbox'
    ],

    title: 'Change Gene Interest',
    resizable: false,
    layout: 'fit',
    closeAction: 'hide',
    cls: 'plan editor',

    constructor: function (config) {
        if(Ext.isIE7 || Ext.isIE8) {
            config.width = 400;
        }
        return this.callParent([config]);
    },

    initComponent: function () {
        var editor = this;
        this.callParent();

        var isSubProjectHidden = true;
        if(window.CAN_SEE_SUB_PROJECT) {
            isSubProjectHidden = false;
        };

        this.form = Ext.create('Ext.form.Panel', {
            ui: 'plain',
            margin: '0 0 10 0',
            width: 360,

            layout: 'anchor',
            defaults: {
                anchor: '100%',
                labelWidth: 150,
                labelAlign: 'right',
                labelPad: 10
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
                xtype: 'simplecombo',
                fieldLabel: 'Consortium',
                name: 'consortium_name',
                storeOptionsAreSpecial: true,
                store: window.CONSORTIUM_OPTIONS
            },
            {
                id: 'production_centre_name',
                xtype: 'simplecombo',
                fieldLabel: 'Production Centre',
                name: 'production_centre_name',
                storeOptionsAreSpecial: true,
                store: window.CENTRE_OPTIONS
            },
            {
                id: 'status_name',
                xtype: 'textfield',
                fieldLabel: 'Status',
                name: 'status_name',
                readOnly: true
            },
            {
                id: 'priority_name',
                xtype: 'simplecombo',
                fieldLabel: 'Priority',
                name: 'priority_name',
                store: window.PRIORITY_OPTIONS
            },
            {
                id: 'phenotype_only',
                xtype: 'simplecheckbox',
                fieldLabel: 'Phenotype only?',
                name: 'phenotype_only'
            },
            {
                id: 'is_conditional_allele',
                xtype: 'simplecheckbox',
                fieldLabel: 'Conditional allele?',
                name: 'is_conditional_allele'
            },
            {
                id: 'is_deletion_allele',
                xtype: 'simplecheckbox',
                fieldLabel: 'Deletion allele?',
                name: 'is_deletion_allele'
            },
            {
                id: 'is_cre_knock_in_allele',
                xtype: 'simplecheckbox',
                fieldLabel: 'Cre knock-in allele?',
                name: 'is_cre_knock_in_allele'
            },
            {
                id: 'is_cre_bac_allele',
                xtype: 'simplecheckbox',
                fieldLabel: 'Cre BAC allele?',
                name: 'is_cre_bac_allele'
            },
            {
                id: 'is_bespoke_allele',
                xtype: 'simplecheckbox',
                fieldLabel: 'Bespoke allele?',
                name: 'is_bespoke_allele',
                hidden: isSubProjectHidden
            },
            {
                id: 'comment',
                xtype: 'textfield',
                fieldLabel: 'Allele Type Comment',
                name: 'comment'
            },
            {
                id: 'sub_project_name',
                xtype: 'simplecombo',
                fieldLabel: 'Sub-Project',
                name: 'sub_project_name',
                storeOptionsAreSpecial: true,
                store: window.SUB_PROJECT_OPTIONS,
                hidden: isSubProjectHidden
            },
            {
                id: 'number_of_es_cells_starting_qc',
                xtype: 'simplenumberfield',
                fieldLabel: '# of ES Cells starting QC',
                name: 'number_of_es_cells_starting_qc'
            },
            {
                id: 'number_of_es_cells_passing_qc',
                xtype: 'simplenumberfield',
                fieldLabel: '# of ES Cells passing QC',
                name: 'number_of_es_cells_passing_qc'
            },
            {
                id: 'es_qc_comment_name',
                xtype: 'simplecombo',
                fieldLabel: 'ES QC Comment',
                name: 'es_qc_comment_name',
                storeOptionsAreSpecial: true,
                store: window.ES_QC_COMMENT_NAMES
            }
            ],

            buttons: [
            {
                id: 'update-button',
                text: '<strong>Update</strong>',
                handler: function (button) {
                    button.disable();

                    var message = null;

                    if(Ext.isEmpty(editor.miPlan.get('number_of_es_cells_passing_qc')) &&
                        !Ext.isEmpty(editor.form.getComponent('number_of_es_cells_passing_qc').getValue())) {
                        if(editor.form.getComponent('number_of_es_cells_passing_qc').getValue() == 0) {
                            message = 'Saving these changes will force the status to "Aborted - ES Cell QC Failed"';
                        } else {
                            message = 'Saving these changes will force the status to "Assigned - ES Cell QC Complete"';
                        }

                    } else if(Ext.isEmpty(editor.miPlan.get('number_of_es_cells_starting_qc')) &&

                        !Ext.isEmpty(editor.form.getComponent('number_of_es_cells_starting_qc').getValue())) {

                        message = 'Saving these changes will force the status to "Assigned - ES Cell QC In Progress"';
                    }

                    if(!Ext.isEmpty(message)) {
                        Ext.Msg.show({
                            title:'Notice',
                            msg: message + " - is that OK?",
                            buttons: Ext.Msg.YESNO,
                            icon: Ext.Msg.QUESTION,
                            closable: false,
                            fn: function (clicked) {
                                if(clicked === 'yes') {
                                    editor.updateAndHide();
                                } else {
                                    button.enable();
                                }
                            }
                        });
                    } else {
                        editor.updateAndHide();
                    }
                }
            },
            {
                text: 'Cancel',
                handler: function () {
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
            margin: '0 0 5 0',
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
                handler: function (button) {
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
                handler: function (button) {
                    editor.setLoading(true);
                    editor.miPlan.destroy({
                        success: function () {
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

        var withdrawContainer = Ext.create('Ext.panel.Panel', {
            ui: 'plain',
            layout: {
                type: 'hbox',
                align: 'stretchmax'
            },
            margin: '0 0 5 0',
            items: [
            {
                xtype: 'label',
                text: "Withdraw interest",
                cls: 'x-form-item-label',
                margin: '0 5 0 0'
            },
            {
                xtype: 'button',
                id: 'withdraw-button',
                text: 'Withdraw',
                width: 60,
                handler: function (button) {
                    button.hide();
                    withdrawContainer.getComponent('withdraw-confirmation-button').show();
                }
            },
            {
                xtype: 'button',
                id: 'withdraw-confirmation-button',
                text: 'Are you sure?',
                width: 100,
                hidden: true,
                handler: function (button) {
                    editor.setLoading(true);
                    var miPlan = editor.miPlan;

                    miPlan.set('withdrawn', true);
                    editor.miPlan.save({
                        success: function () {
                            editor.setLoading(false);
                            editor.hide();
                        }
                    });
                    button.hide();
                    withdrawContainer.getComponent('withdraw-button').show();
                }
            }
            ]
        });

        var inactivateContainer = Ext.create('Ext.panel.Panel', {
            ui: 'plain',
            layout: {
                type: 'hbox',
                align: 'stretchmax'
            },
            margin: '0 0 5 0',
            items: [
            {
                xtype: 'label',
                text: "Inactivate plan?",
                cls: 'x-form-item-label',
                margin: '0 5 0 0'
            },
            {
                xtype: 'button',
                id: 'inactivate-button',
                text: 'Inactivate',
                width: 60,
                handler: function (button) {
                    button.hide();
                    inactivateContainer.getComponent('inactivate-confirmation-button').show();
                }
            },
            {
                xtype: 'button',
                id: 'inactivate-confirmation-button',
                text: 'Are you sure?',
                width: 100,
                hidden: true,
                handler: function (button) {
                    editor.setLoading(true);
                    var miPlan = editor.miPlan;

                    miPlan.set('is_active', false);
                    editor.miPlan.save({
                        success: function () {
                            editor.setLoading(false);
                            editor.hide();
                        }
                    });
                    button.hide();
                    inactivateContainer.getComponent('inactivate-button').show();
                }
            }
            ]
        });
        var panelHeight = 520;
        if(window.CAN_SEE_SUB_PROJECT) {
            panelHeight = 540;
        }

        this.add(Ext.create('Ext.panel.Panel', {
            height: panelHeight,
            ui: 'plain',
            layout: {
                type: 'vbox',
                align: 'stretchmax'
            },
            padding: 5,
            items: [
            editor.form,
            deleteContainer,
            withdrawContainer,
            inactivateContainer
            ]
        }));

        editor.updateButton = Ext.getCmp('update-button');
        this.addListener('hide', function () {
            editor.updateButton.enable();
        });

        editor.withdrawButton = Ext.getCmp('withdraw-button');
        editor.inactivateButton = Ext.getCmp('inactivate-button');

        this.fields = this.form.items.keys;
        this.updateableFields = this.form.items.filterBy(function (i) {
            return i.readOnly != true;
        }).keys;
    },

    edit: function (miPlanId) {
        var editor = this;

        Imits.model.MiPlan.load(miPlanId, {
            success: function (miPlan) {
                editor.miPlan = miPlan;
                Ext.each(editor.fields, function (attr) {
                    var component = editor.form.getComponent(attr);
                    if(component) {
                        component.setValue(editor.miPlan.get(attr));
                    }
                });
                editor.show();

                var component = editor.form.getComponent('consortium_name');
                if(component && (miPlan.get('mi_attempts_count') > 0 || miPlan.get('phenotype_attempts_count') > 0)) {
                    component.setReadOnly(true);
                }

                if(Ext.Array.indexOf(window.WITHDRAWABLE_STATUSES, miPlan.get('status_name')) == -1) {
                    editor.withdrawButton.disable();
                } else {
                    editor.withdrawButton.enable();
                }
            }
        });
    },

    updateAndHide: function () {
        var editor = this;
        Ext.each(this.updateableFields, function (attr) {
            var component = editor.form.getComponent(attr);
            if(component) {
                editor.miPlan.set(attr, component.getValue());
            }
        });

        editor.miPlan.save({
            success: function () {
                editor.hide();
            },

            failure: function () {
                editor.updateButton.enable();
            }
        });
    }

});
