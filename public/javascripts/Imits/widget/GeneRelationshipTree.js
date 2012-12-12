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
        },
        {
            text: 'Sub-project',
            dataIndex: 'sub_project_name',
            width: 200
        }
    ],

    handleMove: function (node, oldParent, newParent) {
        var self = this, newPlanData = newParent.data;

        if (newPlanData.type !== 'MiPlan') {
            Ext.MessageBox.alert('Alert', Ext.String.format('Can only drag onto a Plan'));
        } else if (newPlanData.id === node.data.mi_plan_id) {
            Ext.MessageBox.alert('Alert', Ext.String.format('This {0} already belongs to {1} and {2}',
                                                            node.data.name,
                                                            newPlanData.consortium_name,
                                                            newPlanData.production_centre_name));
        } else {
            var message =
                Ext.String.format("Updating {0} {1}<br>" +
                                  "Old consortium / production centre / plan ID: {2} / {3} / {4}<br>" +
                                  "New consortium / production centre / plan ID: {5} / {6} / {7}<br>",
                                  node.data.name,
                                  node.data.colony_name,
                                  node.data.consortium_name,
                                  node.data.production_centre_name,
                                  node.data.mi_plan_id,
                                  newPlanData.consortium_name,
                                  newPlanData.production_centre_name,
                                  newPlanData.id);
            Ext.MessageBox.confirm('Note', message, function (button) {
                if (button === 'yes') {
                    var modelClass;
                    if (node.data.type === 'MiAttempt') {
                        modelClass = Imits.model.MiAttempt;
                    } else if (node.data.type === 'PhenotypeAttempt') {
                        modelClass = Imits.model.PhenotypeAttempt;
                    } else {
                        throw('Unknown model');
                    }

                    modelClass.load(node.data.id, {
                        success: function (object) {
                            object.set('mi_plan_id', newPlanData.id);
                            object.save({
                                success: function () {
                                    self.getStore().reload();
                                }
                            });
                        }
                    });
                }
            });
        }
    },

    initComponent: function () {
        var self = this;

        self.callParent();

        self.addListener('load', function (thing, records, successful) {
            if (successful) {
                self.expandAll();
            }
        });

        self.addListener('beforeitemmove', function (node, oldParent, newParent, index) {
            if ( ['MiPlan', 'Centre', 'Consortium'].indexOf(newParent.data.type) !== -1 ) {
                self.handleMove(node, oldParent, newParent);
            }

            return false;
        });
    },

    title: '&nbsp;',
    store: Ext.create('Ext.data.TreeStore', {
        fields: [
            {name: 'id', type: 'integer'},
            {name: 'mi_plan_id', type: 'integer'},
            {name: 'name', type: 'string'},
            {name: 'type', type: 'string'},
            {name: 'status', type: 'string'},
            {name: 'colony_name', type: 'string'},
            {name: 'consortium_name', type: 'string'},
            {name: 'production_centre_name', type: 'string'},
            {name: 'sub_project_name', type: 'string'}
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
