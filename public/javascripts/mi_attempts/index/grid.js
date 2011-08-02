Ext.define('Kermits2.MiAttempts.Index.Grid', {
    extend: 'Ext.grid.Panel',
    store: {
        fields: ['id', 'es_cell_name', 'marker_symbol', 'pipeline', 'mutation_subtype', 'production_qc_loxp_screen'],
        data: {
            'rows': []
        },
        proxy: {
            type: 'memory',
            reader: {
                type: 'json',
                root: 'rows'
            }
        }
    },

    bodyStyle: {
      cursor: 'default'
    },
    title: null,
    columns: [
    {
        header: 'ES Cell',
        dataIndex: 'escell_clone',
        width: 100
    },
    {
        header: 'Marker Symbol',
        dataIndex: 'marker_symbol',
        width: 90
    },
    {
        header: 'Pipeline',
        dataIndex: 'pipeline',
        width: 80
    },
    {
        header: 'Mutation Subtype',
        dataIndex: 'mutation_subtype',
        flex: 1
    },
    {
        header: 'LoxP Screen',
        dataIndex: 'production_qc_loxp_screen',
        width: 90
    }
    ],

    initComponent: function() {
        this.callParent();

        this.addListener('itemclick', function(theView, record) {
            var esCellName = record.data['escell_clone'];
            this.initialConfig.esCellSelectorForm.onEsCellNameSelected(esCellName);
        });
    }
});
