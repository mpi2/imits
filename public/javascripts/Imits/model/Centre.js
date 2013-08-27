Ext.define('Imits.model.Centre', {
    extend: 'Ext.data.Model',
    requires: ['Imits.data.Proxy'],

    fields: [
    {
        name: 'id',
        type: 'int',
        persist: false
    },
    {
      name: "name"
    },
    {
      name: "contact_name"
    },
    {
      name: "contact_email"
    }
    ],
    proxy: Ext.create('Imits.data.Proxy', {
        resource: 'centre'
    })
})