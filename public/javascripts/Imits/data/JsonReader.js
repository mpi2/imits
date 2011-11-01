Ext.define('Imits.data.JsonReader', {
    extend: 'Ext.data.reader.Json',
    alias: null,

    readRecords: function(data) {
        if( !this.getRoot(data) && !Ext.isEmpty(data['id'])  ) {
            data = [data];
        }
        return this.callParent([data]);
    },

    getResponseData: function(response) {
        if(response.request.options.method == 'DELETE' &&
            response.status == 200) {
            return {};
        } else {
            return this.callParent([response]);
        }
    }
});
