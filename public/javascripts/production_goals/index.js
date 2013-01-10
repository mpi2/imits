Ext.onReady(function() {
    var grid = Ext.create('Imits.widget.ProductionGoalsGrid', {
        renderTo: 'production-goals-grid'
    });
    Ext.EventManager.onWindowResize(grid.manageResize, grid);
    grid.manageResize();
});
