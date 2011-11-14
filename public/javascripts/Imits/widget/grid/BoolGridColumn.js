Ext.define('Imits.widget.grid.BoolGridColumn', {
    extend: 'Ext.grid.Column',
    alias: 'widget.boolgridcolumn',

    editor: {
        xtype: 'checkbox',
        cls: 'x-grid-checkheader-editor'
    },

    renderer: function (value) {
        var classes = "x-grid-checkheader";
        if(value === true) {
            classes += ' x-grid-checkheader-checked';
        }
        return "<div class=\"" + classes + "\"></div>";
    },

    filter: {
        type: 'boolean',
        defaultValue: null
    }
});
