Ext.onReady(function() {
    var grid = Ext.create('Imits.widget.ContactsGrid', {
        renderTo: 'contacts-grid'
    });
    Ext.EventManager.onWindowResize(grid.manageResize, grid);
    grid.manageResize();
});
