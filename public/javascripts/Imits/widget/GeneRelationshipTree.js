Imits.getStore = function () {
    var consortia = Ext.Array.merge([], window.CONSORTIA);
    var centres = Ext.Array.merge([], window.CENTRES);
    var hierarchy = {};

    Ext.Array.each(consortia, function (consortiumName) {
        hierarchy[consortiumName] = {};
        Ext.Array.each(centres, function (centreName) {
            var leaves = [];
            hierarchy[consortiumName][centreName] = leaves;
        });
    });

    hierarchy['EUCOMM-EUMODIC'].WTSI.push({text: 'MI Attempt', leaf: true});

    hierarchy.BaSH.WTSI.push({text: 'MI Attempt', leaf: true});
    hierarchy.BaSH.WTSI.push({text: 'MI Attempt', leaf: true});
    hierarchy.BaSH.WTSI.push({text: 'Phenotype Attempt', leaf: true});

    hierarchy.DTCC.UCD.push({text: 'MI Attempt', leaf: true});
    hierarchy.BaSH.WTSI.push({text: 'Phenotype Attempt', leaf: true});

    var children = [];

    Ext.Object.each(hierarchy, function (consortiumName, centresHash) {
        var centresInConsortium = [];
        children.push({text: consortiumName, children: centresInConsortium});
        Ext.Object.each(centresHash, function (centreName, leaves) {
            if (Ext.isEmpty(leaves)) {
                centresInConsortium.push({text: centreName, leaf: false});
            } else {
                centresInConsortium.push({text: centreName, children: leaves});
            }
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
