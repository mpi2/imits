Ext.onReady(function() {
    var grid = Ext.create('Imits.widget.MiGrid', {
        renderTo: 'mi-attempts-grid'
    });
    Ext.EventManager.onWindowResize(grid.manageResize, grid);
    grid.manageResize();

    Ext.select('.collapsible-control').each(function(element) {
        element.addListener('click', function() {
            this.manageResize();
        }, grid);
    });
});
