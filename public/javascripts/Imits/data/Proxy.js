Ext.define('Imits.data.Proxy', {
    extend: 'Ext.data.proxy.Rest',
    requires: [
        'Imits.data.JsonWriter',
        'Imits.data.JsonReader'
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
                    var errors = Ext.JSON.decode(response.responseText);
                    var errorHelper = function () {
                        var errorStrings = [];
                        Ext.Object.each(errors, function (key, values) {
                            var errorString =
                                Ext.String.capitalize(key).replace(/_/g, " ") +
                                ": ";
                            if (Ext.isString(values)) {
                                errorString += values;
                            } else if (Ext.isArray) {
                                errorString += values.join(", ");
                            }
                            errorStrings.push(errorString);
                        });
                        return errorStrings.join("<br/>");
                    };
                    Ext.MessageBox.show({
                        title: 'Error',
                        msg: errorHelper(errors),
                        icon: Ext.MessageBox.ERROR,
                        buttons: Ext.Msg.OK,
                        fn: function (buttonid, text, opt) {
                            console.log('TODO: Refresh the cell/row that was changed');
                        }
                    });
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
