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
                centresInConsortium.push({name: centreName, children: leaves});
            }
        });

        if (!Ext.isEmpty(centresInConsortium)) {
            children.push({name: consortiumName, children: centresInConsortium});
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
        },
        {
            text: 'Colony name',
            dataIndex: 'colony_name',
            width: 200
        }
    ],

    initComponent: function () {
        var self = this;

        self.callParent();

        self.addListener('load', function (thing, records, successful) {
            if (successful) {
                self.expandAll();
            }
        });

        self.addListener('beforeitemmove', function (node, oldParent, newParent, index) {
            console.log({node: node, oldParent: oldParent, newParent: newParent, index: index});
            return false;
        });
    },

    title: '&nbsp;',
    store: Ext.create('Ext.data.TreeStore', {
        fields: [
            {name: 'name', type: 'string'},
            {name: 'status', type: 'string'},
            {name: 'colony_name', type: 'string'}
        ],
        proxy: {
            type: 'ajax',
            url: window.basePath + '/genes/' + window.GENE.mgi_accession_id + '/relationship_tree'
        }
    }),
    rootVisible: false,
    useArrows: true
});
