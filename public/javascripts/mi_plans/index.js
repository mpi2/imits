Ext.onReady(function() {
    var grid;
    if (FULL_ACCESS == true){
        grid = Ext.create('Imits.widget.MiPlansGrid', {
            renderTo: 'mi-plans-grid'
        });
    }
    else {
        grid = Ext.create('Imits.widget.MiPlansGridGeneral', {
            renderTo: 'mi-plans-grid'
        });
    }
    Ext.EventManager.onWindowResize(grid.manageResize, grid);
    grid.manageResize();
});
