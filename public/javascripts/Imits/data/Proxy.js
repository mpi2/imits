Ext.define('Imits.data.Proxy', {
    extend: 'Ext.data.proxy.Rest',
    requires: ['Imits.data.JsonWriter'],

    constructor: function(config) {
        var resource = config.resource;

        this.callParent([{
            format: 'json',
            url: basePath + '/' + resource + 's',
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
            }),

            encodeSorters: function(sorters) {
                if(sorters.length == 0) {
                    return "";
                } else {
                    var sorter = sorters[0]
                    return sorter.property + ' ' + sorter.direction.toLowerCase();
                }
            }
        }]);
    }
});
