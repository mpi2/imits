Ext.define('Imits.widget.SimpleCombo', {
    extend: 'Ext.form.field.ComboBox',
    alias: 'widget.simplecombo',
    typeAhead: false,
    triggerAction: 'all',
    forceSelection: true,
    editable: false,

    constructor: function(config) {
        if(config.storeOptionsAreSpecial == true) {
            var mapper = function(i) {
                if(Ext.isEmpty(i)) {
                    return[i, window.NO_BREAK_SPACE];
                } else {
                    return [i, Ext.String.htmlEncode(i)];
                }
            };
            config.store = Ext.Array.map(config.store, mapper);
        }
        this.callParent([config]);
    },

    initComponent: function() {
        this.callParent();

        if(this.storeOptionsAreSpecial == true) {
            this.displayTpl = Ext.create('Ext.XTemplate',
                '<tpl for=".">' +
                '{[typeof values === "string" ? values : values["' + this.valueField + '"]]}' +
                '<tpl if="xindex < xcount">' + this.delimiter + '</tpl>' +
                '</tpl>'
                );
        }
    }
});
