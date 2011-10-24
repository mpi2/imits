Ext.define('Imits.data.JsonReader', {
    extend: 'Ext.data.reader.Json',
    alias: null,

    readRecords: function(data) {
        if( !this.getRoot(data) && !Ext.isEmpty(data['id'])  ) {
            data = [data];
        }
        return this.callParent([data]);
    }
});
