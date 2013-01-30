Ext.define('Imits.model.Contact', {
    extend: 'Ext.data.Model',
    requires: ['Imits.data.Proxy'],

    fields: [
    {
        name: 'id',
        type: 'int',
        persist: false
    },
    {
      name: "email"
    }
    ],
    proxy: Ext.create('Imits.data.Proxy', {
        resource: 'admin_contact',
        resourcePath: 'admin/contacts'
    })
})