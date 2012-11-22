Imits.getStore = function () {
    var consortia = Ext.Array.merge([], window.CONSORTIA);
    var centres = Ext.Array.merge([], window.CENTRES);
    var children = [];

    Ext.Array.each(consortia, function (consortiumName) {
        var centresInConsortium = [];
        children.push({text: consortiumName, children: centresInConsortium});
        Ext.Array.each(centres, function (centreName) {
            centresInConsortium.push({text: centreName, leaf: false});
        });
    });

    var store = Ext.create('Ext.data.TreeStore', {
        root: {
            expanded: true,
            text: 'Xxx1',
            children: children
        }
    });
    return store;
};

Ext.define('Imits.widget.GeneRelationshipTree', {
    extend: 'Ext.tree.Panel',

    requires: [
        'Ext.data.TreeStore',
        'Ext.tree.plugin.TreeViewDragDrop'
    ],

    mixins: [
        'Imits.widget.ManageResizeWithBrowserFrame'
    ],

    viewConfig: {
        plugins: {
            ptype: 'treeviewdragdrop',
            containerScroll: true
        }
    },

    title: 'Relationship Tree',
    store: Imits.getStore(),
    rootVisible: true,
    useArrows: true,
    height: 600
});
