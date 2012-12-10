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
                store: window.CONSORTIUM_OPTIONS,
                listeners : {
                  change : function() {
                       var no_mi_attempts = editor.miPlan.get('mi_attempts_count')
                       var no_phenotype_attempts = editor.miPlan.get('phenotype_attempts_count')
                       if (no_mi_attempts != 0 || no_phenotype_attempts != 0){
                         message = "This will also affect "
                         if (no_mi_attempts != 0 ) {
                           message = message + no_mi_attempts + " Mouse Injection attempt ";
                           if (no_phenotype_attempts != 0) {
                             message = message + "and ";
                           }
                         }
                         if (no_phenotype_attempts != 0) {
                           message = message + no_phenotype_attempts + " Phenotype attempts ";
                         }
                         message = message + "- Do you want to continue?";
                       } else {
                         message = "This will change the consortium for this plan,  - Do you want to continue?";
                       }
                       Ext.Msg.show({
                            title:'Consortium Change',
                            msg: message,
                            buttons: Ext.Msg.YESNO,
                            icon: Ext.Msg.QUESTION,
                            closable: false,
                            fn: function (clicked) {
                                if(clicked === 'no') {
                                    component = editor.form.getComponent('consortium_name');
                                    editor.form.getComponent('consortium_name').suspendEvents();
                                    component.setValue(editor.miPlan.get('consortium_name'));
                                    editor.form.getComponent('consortium_name').resumeEvents();


                                }
                            }
                        });
                  }}
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
                    editor.setLoading(false);
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
                    editor.setLoading(false);
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
                id: 'inactive-plan',
                text: "Inactivate plan?",
                hidden: true,
                cls: 'x-form-item-label',
                margin: '0 5 0 0'
            },
            {
                xtype: 'button',
                id: 'inactivate-button',
                text: 'Inactivate',
                hidden: true,
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
                    editor.setLoading(false);
                    button.hide();
                    inactivateContainer.getComponent('inactive-plan').hide();
                    inactivateContainer.getComponent('active-plan').show();
                    inactivateContainer.getComponent('activate-button').show();
                }
            },
            {
                xtype: 'label',
                id: 'active-plan',
                text: "Activate plan?",
                hidden: true,
                cls: 'x-form-item-label',
                margin: '0 5 0 0'
            },
            {
                xtype: 'button',
                id: 'activate-button',
                text: 'Activate',
                hidden: true,
                width: 60,
                handler: function (button) {
                    button.hide();
                    inactivateContainer.getComponent('activate-confirmation-button').show();
                }
            },
            {
                xtype: 'button',
                id: 'activate-confirmation-button',
                text: 'Are you sure?',
                hidden: true,
                width: 100,
                hidden: true,
                handler: function (button) {
                    editor.setLoading(true);
                    var miPlan = editor.miPlan;

                    miPlan.set('is_active', true);
                    editor.miPlan.save({
                        success: function () {
                            editor.setLoading(false);
                            editor.hide();
                        }
                    });
                    editor.setLoading(false);
                    button.hide();
                    inactivateContainer.getComponent('active-plan').hide();
                    inactivateContainer.getComponent('inactive-plan').show();
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
        editor.activateButton = Ext.getCmp('activate-button');
        editor.deleteButton = Ext.getCmp('delete-button');

        this.fields = this.form.items.keys;
        this.updateableFields = this.form.items.filterBy(function (i) {
            return i.readOnly != true;
        }).keys;
    },

    edit: function (miPlanId) {
        var editor = this;
        editor.form.getComponent('consortium_name').suspendEvents()
        Imits.model.MiPlan.load(miPlanId, {
            success: function (miPlan) {
                editor.miPlan = miPlan;
                Ext.each(editor.fields, function (attr) {
                    var component = editor.form.getComponent(attr);
                    if(component) {
                        component.setValue(editor.miPlan.get(attr));
                    }
                });
                editor.form.getComponent('consortium_name').resumeEvents();

                //reset buttons between loads/ hide and show
                Ext.getCmp('delete-confirmation-button').hide();
                editor.deleteButton.show();
                Ext.getCmp('withdraw-confirmation-button').hide();
                editor.withdrawButton.show();
                if (editor.miPlan.get('is_active')) {
                  Ext.getCmp('active-plan').hide();
                  editor.activateButton.hide();
                  Ext.getCmp('inactive-plan').show();
                  editor.inactivateButton.show();
                } else {
                  Ext.getCmp('inactive-plan').hide();
                  editor.inactivateButton.hide();
                  Ext.getCmp('active-plan').show();
                  editor.activateButton.show();
                }
                Ext.getCmp('inactivate-confirmation-button').hide();
                Ext.getCmp('activate-confirmation-button').hide();
                editor.show();

   //             var component = editor.form.getComponent('consortium_name');
   //             if(component && (miPlan.get('mi_attempts_count') > 0 || miPlan.get('phenotype_attempts_count') > 0)) {
     //               component.setReadOnly(true);
       //         }

                if(Ext.Array.indexOf(window.WITHDRAWABLE_STATUSES, miPlan.get('status_name')) == -1) {
                    editor.withdrawButton.disable();
                } else {
                    editor.withdrawButton.enable();
                }
                if (editor.miPlan.get('mi_attempts_count') == 0 && editor.miPlan.get('phenotype_attempts_count') == 0) {
                  editor.deleteButton.enable();
                } else {
                  editor.deleteButton.disable();
                }
                if (editor.miPlan.get('has_active_mi_attempts?') || editor.miPlan.get('has_active_phenotype_attempts?')) {
                  editor.inactivateButton.disable();
                  editor.activateButton.disable();
                } else {
                  editor.inactivateButton.enable();
                  editor.activateButton.ensable();
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
