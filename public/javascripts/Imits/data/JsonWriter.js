Ext.define('Imits.data.JsonWriter', {
    extend: 'Ext.data.writer.Json',
    writeAllFields: false,
    write: function(originalRequest) {
        var request = this.callParent([originalRequest]);
        request.params['authenticity_token'] = window.authenticityToken;
        if(request.jsonData[this.root] && request.jsonData[this.root]['id']) {
            delete request.jsonData[this.root]['id'];
        }
        return request;
    }
});
