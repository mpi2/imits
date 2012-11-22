Imits.getStore = function () {
    var consortia = Ext.Array.merge([], window.CONSORTIA);
    var centres = Ext.Array.merge([], window.CENTRES);
    var children = [];

    Ext.Array.each(consortia, function (consortiumName) {
        var centresInConsortium = [];
        children.push({text: consortiumName, children: centresInConsortium});
        Ext.Array.each(centres, function (centreName) {
            centresInConsortium.push({text: centreName, leaf: true});
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
        'Ext.data.TreeStore'
    ],

    mixins: [
        'Imits.widget.ManageResizeWithBrowserFrame'
    ],

    title: 'Relationship Tree',
    store: Imits.getStore(),
    rootVisible: true,
    height: 600
});
