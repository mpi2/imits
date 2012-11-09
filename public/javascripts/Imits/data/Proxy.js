Ext.define('Imits.data.Proxy', {
    extend: 'Ext.data.proxy.Rest',
    requires: [
    'Imits.data.JsonWriter',
    'Imits.data.JsonReader',
    'Imits.Util'
    ],

    constructor: function (config) {
        var resource = config.resource;
        var resourcePath = resource + 's';

        if (config.resourcePath) {
            resourcePath = config.resourcePath;
        }

        this.callParent([{
            format: 'json',
            url: window.basePath + '/' + resourcePath,
            extraParams: {
                'extended_response': true
            },
            startParam: undefined,
            limitParam: 'per_page',
            sortParam: 'sorts',

            reader: Ext.create('Imits.data.JsonReader', {
                root: resource + 's'
            }),

            writer: Ext.create('Imits.data.JsonWriter', {
                root: resource,
                writeAllFields: false
            }),

            listeners: {
                exception: function (proxy, response, operation) {
                    Imits.Util.handleErrorResponse(response);
                }
            },

            encodeSorters: function(sorters) {
                if (sorters.length === 0) {
                    return "";
                } else {
                    var sorter = sorters[0];
                    return sorter.property + ' ' + sorter.direction.toLowerCase();
                }
            }
        }]);
    }
});
