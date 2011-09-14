Ext.define('Imits.widget.Grid', {
  extend: 'Ext.grid.Panel',
  manageResize: function() {
    var windowHeight = window.innerHeight - 30;
    if(!windowHeight) {
      windowHeight = document.documentElement.clientHeight - 30;
    }
    var newGridHeight = windowHeight - this.getEl().getTop();
    if(newGridHeight < 200) {
      newGridHeight = 200;
    }
    this.setHeight(newGridHeight);
    this.setWidth(this.getEl().up('div').getWidth());
    this.doLayout();
  }
});
