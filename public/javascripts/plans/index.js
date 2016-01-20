Ext.onReady(function() {
    var grid;
    if (FULL_ACCESS == true){
        grid = Ext.create('Imits.widget.PlansGrid', {
            renderTo: 'plans-grid'
        });
    }
    else {
        grid = Ext.create('Imits.widget.PlansGridGeneral', {
            renderTo: 'plans-grid'
        });
    }
    Ext.EventManager.onWindowResize(grid.manageResize, grid);
    grid.manageResize();
});
