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
      name: "background_strain",
      defaultValue: false
    },
    {
      name: "test_cross_strain",
      defaultValue: false
    },
    {
      name: "blast_strain",
      defaultValue: false
    }
    ],
    proxy: Ext.create('Imits.data.Proxy', {
        resource: 'strain'
    })
})
