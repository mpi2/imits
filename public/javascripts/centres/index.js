Ext.onReady(function() {
    var grid = Ext.create('Imits.widget.CentresGrid', {
        renderTo: 'centres-grid'
    });
    Ext.EventManager.onWindowResize(grid.manageResize, grid);
    grid.manageResize();
});
