Ext.onReady(function() {
    var grid = Ext.create('Imits.widget.NotificationsGrid', {
        renderTo: 'notifications-grid'
    });
    Ext.EventManager.onWindowResize(grid.manageResize, grid);
    grid.manageResize();
});
