Ext.define('Imits.widget.Grid', {
    extend: 'Ext.grid.Panel',

    mixins: [
        'Imits.widget.ManageResizeWithBrowserFrame'
    ],

    reloadStore: function() {
        var store = this.getStore();
        store.sync();
        store.load();
    }
});
