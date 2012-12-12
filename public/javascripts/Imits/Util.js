Ext.define('Imits.Util', {
    statics: {
        handleErrorResponse: function (response) {
            var errors = Ext.JSON.decode(response.responseText);
            var errorHelper = function () {
                var errorStrings = [];
                if (errors.hasOwnProperty('backtrace')) {
                    delete errors.backtrace;
                }
                Ext.Object.each(errors, function (key, values) {
                    var errorString =
                    Ext.String.capitalize(key).replace(/_/g, " ") +
                    ": ";
                    if (Ext.isString(values)) {
                        errorString += values;
                    } else if (Ext.isArray) {
                        errorString += values.join(", ");
                    }
                    errorStrings.push(Ext.String.htmlEncode(errorString));
                });
                return errorStrings.join("<br/>");
            };
            Ext.MessageBox.show({
                title: 'Error',
                msg: errorHelper(errors),
                icon: Ext.MessageBox.ERROR,
                buttons: Ext.Msg.OK,
                fn: function (buttonid, text, opt) {
                // TODO: Refresh the cell/row that was changed
                }
            });
        },

        extractValueIfExistent: function (object, valueName) {
            if (Ext.isEmpty(object) || !object.hasOwnProperty(valueName)) {
                return undefined;
            }

            var value = object[valueName];

            if (!Ext.isEmpty(value)) {
                return value;
            } else {
                return undefined;
            }
        }

    }
});
