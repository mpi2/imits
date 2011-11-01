Ext.define('Imits.data.JsonWriter', {
    extend: 'Ext.data.writer.Json',
    writeAllFields: false,
    write: function(originalRequest) {
        var request = this.callParent([originalRequest]);
        request.params['authenticity_token'] = window.authenticityToken;
        if(request.jsonData[this.root] && request.jsonData[this.root]['id']) {
            delete request.jsonData[this.root]['id'];
        }

        if(request.action === "destroy" && !Ext.isEmpty(request.params)) {
            // Set params as URL parameters if DELETE request instead of passing
            // them through as JSON in the body, or certain proxies complain
            request.url = Ext.urlAppend(request.url, Ext.urlEncode(request.params));
            request.jsonData = null;
            request.params = null;
        }

        return request;
    }
});
