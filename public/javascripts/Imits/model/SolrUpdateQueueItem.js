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
        name: 'reference'
    },
    {
        name: 'action'
    },
    {
        name: 'created_at'
    }
    ],

    proxy: Ext.create('Imits.data.Proxy', {
        resource: 'solr_update_queue_item',
        resourcePath: 'solr_update/queue/items'
    })
});
