Ext.onReady(function() {
    var grid = Ext.create('Imits.widget.TrackingGoalsConsortiaBreakdownGrid', {
        renderTo: 'tracking-goals-consortia-breakdown-grid'
    });
    Ext.EventManager.onWindowResize(grid.manageResize, grid);
    grid.manageResize();
});
