Ext.define('Imits.model.Notification', {
    extend: 'Ext.data.Model',
    requires: ['Imits.data.Proxy'],

    fields: [
    {
        name: 'id',
        type: 'int',
        persist: false
    },
    {
      name: "contact_id"
    },
    {
      name: "contact_email"
    },
    {
      name: "gene_id"
    },
    {
      name: "gene_marker_symbol"
    },
    {
      name: "welcome_email_sent"
    },
    {
      name: "last_email_sent"
    },
    {
      name: "welcome_email"
    },
    {
      name: "last_email"
    }
    ],
    proxy: Ext.create('Imits.data.Proxy', {
        resource: 'notification',
        resourcePath: 'admin/notifications'
    })
})