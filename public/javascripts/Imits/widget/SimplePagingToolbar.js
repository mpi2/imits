Ext.define('Imits.widget.SimplePagingToolbar', {
    extend: 'Ext.toolbar.Paging',
    alias: 'widget.simplepagingtoolbar',
    items: [
        {
            text: 'Download Data',
            cls:'x-btn-text-icon',
            iconCls: 'icon-add',
            handler: function() {
                grid.downloadData();
            }
        }
    ]
});
