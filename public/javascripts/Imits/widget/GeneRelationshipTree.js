Ext.define('Imits.widget.GeneRelationshipTree', {
    extend: 'Ext.tree.Panel',

    requires: [
        'Ext.data.TreeStore',
        'Ext.tree.plugin.TreeViewDragDrop',
        'Imits.widget.ManageResizeWithBrowserFrame'
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
            {name: 'id', type: 'integer'},
            {name: 'name', type: 'string'},
            {name: 'status', type: 'string'},
            {name: 'colony_name', type: 'string'}
        ],

        proxy: {
            type: 'ajax',
            url: (function () {
                if (window.GENE) {
                    return window.basePath + '/genes/' + window.GENE.mgi_accession_id + '/relationship_tree.json';
                } else {
                    return '';
                }
            }())
        }

    }),
    rootVisible: false,
    useArrows: true
});
