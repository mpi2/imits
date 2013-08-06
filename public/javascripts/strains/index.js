Ext.onReady(function() {
    var grid = Ext.create('Imits.widget.StrainsGrid', {
        renderTo: 'strains-grid'
    });
    Ext.EventManager.onWindowResize(grid.manageResize, grid);
    grid.manageResize();
});
