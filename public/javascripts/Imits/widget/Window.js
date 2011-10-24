Ext.define('Imits.widget.Window', {
    extend: 'Ext.window.Window',

    plain: true,

    showLoadMask: function() {
        this.loadMask = new Ext.LoadMask(this.getComponent(0).getEl());
        this.loadMask.show();
    },

    hideLoadMask: function() {
        this.loadMask.hide();
    }
});
