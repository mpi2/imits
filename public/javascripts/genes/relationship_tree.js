Ext.onReady(function () {
    var tree = Ext.create('Imits.widget.GeneRelationshipTree', {
        renderTo: 'relationship-tree'
    });
    Ext.EventManager.onWindowResize(tree.manageResize, tree);
    tree.manageResize();
});
