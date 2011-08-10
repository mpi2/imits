Ext.define('Imits.data.Proxy', {
    extend: 'Ext.data.proxy.Rest',

    constructor: function(config) {
        var resource = config.resource;

        this.callParent([{
            type: 'rest',
            format: 'json',
            url: '/' + resource + 's',
            extraParams: {
                'extended_response': true
            },
            startParam: undefined,
            limitParam: 'per_page',
            sortParam: 'sorts',
            reader: {
                type: 'json',
                root: resource + 's'
            },
            writer: Ext.create('Imits.data.JsonWriter', {
                root: resource,
                writeAllFields: false
            })
        }]);
    }
});
