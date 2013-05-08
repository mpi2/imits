Ext.onReady(function() {
    var grid = Ext.create('Imits.widget.TrackingGoalsGrid', {
        renderTo: 'tracking-goals-grid'
    });
    Ext.EventManager.onWindowResize(grid.manageResize, grid);
    grid.manageResize();
});
