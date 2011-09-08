Ext.define('Imits.widget.grid.SimpleDateColumn', {
    extend: 'Ext.grid.column.Date',
    alias: 'widget.simpledatecolumn',

    format: 'd-m-Y',
    editor: {
        xtype: 'datefield',
        format: 'd-m-Y'
    },
    filter: {
        type: 'date'
    }
});
