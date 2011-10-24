Ext.define('Imits.widget.MiPlanEditor', {
    extend: 'Imits.widget.Window',

    requires: [
    'Imits.model.MiPlan'
    ],

    title: 'Change Expression of Interest to Micro-Inject',
    resizable: false,
    layout: 'fit',
    closeAction: 'hide',

    initComponent: function() {
        var editor = this;
        this.callParent();

        this.form = Ext.create('Ext.form.Panel', {
            ui: 'plain',
            // border below

            items: [
            {
                id: 'consortium_name',
                xtype: 'textfield',
                fieldLabel: 'Consortium',
                name: 'consortium_name',
                readOnly: true
            }
            ],

            buttons: [
            {
                text: 'Update'
            },
            {
                text: 'Cancel',
                handler: function() {
                    editor.hide();
                }
            },
            ]
        });

        var deleteContainer = Ext.create('Ext.panel.Panel', {
            ui: 'plain',
            layout: 'hbox',
            items: [
            {
                xtype: 'label',
                text: 'Delete this expression of interest to micro-inject?',
                cls: 'x-form-item-label'
                // border right
            },
            {
                xtype: 'button',
                text: 'Delete',
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

        this.add(Ext.create('Ext.panel.Panel', {
            ui: 'plain',
            padding: 15,
            items: [
            this.form,
            deleteContainer
            ]
        }));
    },

    edit: function(miPlanId) {
        var editor = this;

        Imits.model.MiPlan.load(miPlanId, {
            success: function(miPlan) {
                editor.miPlan = miPlan;
                editor.form.getComponent('consortium_name').setValue(miPlan.get('consortium_name'));
                editor.show();
            }
        });
    }
});
