Ext.onReady(function() {
    var grid = Ext.create('Imits.widget.SolrUpdateQueueItemsGrid', {
        renderTo: 'solr-update-queue-items-grid'
    });
    Ext.EventManager.onWindowResize(grid.manageResize, grid);
    grid.manageResize();
});
