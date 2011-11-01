Ext.define('Imits.data.Proxy', {
    extend: 'Ext.data.proxy.Rest',
    requires: [
        'Imits.data.JsonWriter',
        'Imits.data.JsonReader'
    ],

    constructor: function(config) {
        var resource = config.resource;

        this.callParent([{
            format: 'json',
            url: window.basePath + '/' + resource + 's',
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
                exception: function(proxy, response, operation){
                    var errs = Ext.JSON.decode(response.responseText);
                    Ext.MessageBox.show({
                        title: 'REMOTE EXCEPTION',
                        msg: Ext.Object.getValues(errs).join(', '),
                        icon: Ext.MessageBox.ERROR,
                        buttons: Ext.Msg.OK,
                        fn: function(buttonid, text, opt) {
                            console.log('TODO: Refresh the cell/row that was changed');
                        }
                    });
                }
            },

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
