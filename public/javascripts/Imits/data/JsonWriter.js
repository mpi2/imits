Ext.define('Imits.data.JsonWriter', {
    extend: 'Ext.data.writer.Json',
    writeAllFields: false,
    write: function(originalRequest) {
        var request = this.callParent([originalRequest]);
        request.jsonData['authenticity_token'] = window.authenticityToken;
        return request;
    }
});
