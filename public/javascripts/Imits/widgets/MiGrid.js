Ext.define('Imits.widgets.MiGrid', {
    extend: 'Ext.grid.Panel',
    title: 'Micro-Injection Attempts',
    store: {
        model: 'Imits.model.MiAttempt',
        autoLoad: true
    },
    columns: [
    {
        header: 'ID',
        dataIndex: 'id',
        hidden: true
    },
    {
        header: 'ES Cell Name',
        dataIndex: 'es_cell_name'
    },
    {
        header: 'Colony Name',
        dataIndex: 'colony_name'
    }
    ],

    initComponent: function() {
        this.callParent();
    }
});
