Ext.define('Imits.widget.SimpleCheckbox', {
    extend: 'Ext.form.field.Checkbox',
    alias: 'widget.simplecheckbox',

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
