Ext.define('Imits.widget.grid.BoolGridColumn', {
    extend: 'Ext.grid.column.Column',
    alias: 'widget.boolgridcolumn',

    editor: 'checkbox',
    renderer: function(value) {
        if(value == true) {
            return '<input type="checkbox" checked=1></input>';
        } else {
            return '<input type="checkbox"></input>';
        }
    },

    filter: {
        type: 'boolean',
        defaultValue: null
    }
});
