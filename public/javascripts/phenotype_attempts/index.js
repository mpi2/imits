Ext.onReady(function() {
    var grid = Ext.create('Imits.widget.PhenotypeAttemptsGrid', {
        renderTo: 'phenotype-attempts-grid'
    });
    Ext.EventManager.onWindowResize(grid.manageResize, grid);
    grid.manageResize();
});
