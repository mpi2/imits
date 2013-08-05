Ext.define('Imits.model.Strain', {
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
      name: "mgi_strain_accession_id"
    },
    {
      name: "mgi_strain_name"
    }
    ],
    proxy: Ext.create('Imits.data.Proxy', {
        resource: 'strain'
    })
})


mgi_strain_name