Ext.define('Imits.widget.NotificationPane', {
    extend: 'Imits.widget.Window',

    requires: [
    'Imits.model.Notification'
    ],

    title: 'View Notification',
    resizable: true,
    layout: 'fit',
    closeAction: 'hide',
    cls: 'notification view',

    constructor: function (config) {
        //if(Ext.isIE7 || Ext.isIE8) {
        //    config.width = 400;
        //}
        return this.callParent([config]);
    },

    initComponent: function () {
        var editor = this;
        this.callParent();

        this.form = Ext.create('Ext.form.Panel', {
            ui: 'plain',
            margin: '0 0 10 0',
            width: 600,

            layout: 'anchor',
            defaults: {
                anchor: '100%',
                labelWidth: 150,
                labelAlign: 'right',
                labelPad: 10
            },

            items: [
            {
                id: 'welcome_email',
                xtype: 'textarea',
                fieldLabel: 'Welcome email',
                name: 'welcome_email',
                height: 230,
                readOnly: true
            },
            {
                id: 'last_email',
                xtype: 'textarea',
                fieldLabel: 'Last email',
                name: 'last_email',
                height: 230,
                readOnly: true
            }
            ],

            buttons: [
                {
                    text: 'Cancel',
                    handler: function () {
                        editor.hide();
                    }
                }
            ]
        });

        
        var panelHeight = 520;
        
        this.add(Ext.create('Ext.panel.Panel', {
            height: panelHeight,
            ui: 'plain',
            layout: {
                type: 'vbox',
                align: 'stretchmax'
            },
            padding: 5,
            items: [
                editor.form
            ]
        }));

        this.fields = this.form.items.keys;
    },
    load: function (notificationId) {
        var editor = this;

        Imits.model.Notification.load(notificationId, {
            success: function (notification) {
                editor.notification = notification;
                Ext.each(editor.fields, function (attr) {
                    var component = editor.form.getComponent(attr);
                    if(component) {
                        component.setValue(editor.notification.get(attr));
                    }
                });
                editor.show();
            }
        });
    },
});
