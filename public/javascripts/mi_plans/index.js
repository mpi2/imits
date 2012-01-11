Ext.onReady(function() {
    var grid = Ext.create('Imits.widget.MiPlansGrid', {
        renderTo: 'mi-plans-grid'
    });
    Ext.EventManager.onWindowResize(grid.manageResize, grid);
    grid.manageResize();
});
