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

    hierarchy['EUCOMM-EUMODIC'].WTSI.push({name: 'MI Attempt', status: 'Gentoype confirmed', leaf: true});

    hierarchy.BaSH.WTSI.push({name: 'MI Attempt', status: 'Micro-injection aborted', leaf: true});
    hierarchy.BaSH.WTSI.push({name: 'MI Attempt', status: 'Micro-injection aborted', leaf: true});
    hierarchy.BaSH.WTSI.push({name: 'Phenotype Attempt', status: 'Phenotype Attempt Registered', leaf: true});

    hierarchy.DTCC.UCD.push({name: 'MI Attempt', status: 'Micro-injection in progress', leaf: true});
    hierarchy.BaSH.WTSI.push({name: 'Phenotype Attempt', status: 'Cre Excision Complete', leaf: true});

    var children = [];

    Ext.Object.each(hierarchy, function (consortiumName, centresHash) {
        var centresInConsortium = [];

        Ext.Object.each(centresHash, function (centreName, leaves) {
            if (!Ext.isEmpty(leaves)) {
                centresInConsortium.push({name: centreName, children: leaves, expanded: true});
            }
        });

        if (!Ext.isEmpty(centresInConsortium)) {
            children.push({name: consortiumName, children: centresInConsortium, expanded: true});
        }
    });

    var store = Ext.create('Ext.data.TreeStore', {
        fields: [
            {name: 'name', type: 'string'},
            {name: 'status', type: 'string'}
        ],
        root: {
            expanded: true,
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
            ptype: 'treeviewdragdrop'
        }
    },

    columns: [
        {
            xtype: 'treecolumn',
            dataIndex: 'name',
            text: '&nbsp;',
            flex: 1
        },
        {
            text: 'Status',
            dataIndex: 'status',
            width: 200
        }
    ],

    initComponent: function () {
        var self = this;

        self.callParent();
    },

    title: '&nbsp;',
    store: Imits.getStore(),
    rootVisible: false,
    useArrows: true
});
