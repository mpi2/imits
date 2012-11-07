Ext.define('Imits.model.SolrUpdateQueueItem', {
    extend: 'Ext.data.Model',
    requires: ['Imits.data.Proxy'],

    fields: [
    {
        name: 'id',
        type: 'int',
        persist: false
    },
    {
        name: 'action'
    }
    ],

    proxy: Ext.create('Imits.data.Proxy', {
        resource: 'solr_update/queue/item'
    })
});
