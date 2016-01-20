Ext.define('Imits.widget.PlansGridCommon', {
    extend: 'Imits.widget.Grid',

    requires: [
    'Imits.model.Plan',
    'Imits.widget.grid.RansackFiltersFeature'
    ],

    title: 'Plans',
    iconCls: 'icon-grid',
    columnLines: true,

    store: {
        model: 'Imits.model.Plan',
        autoLoad: true,
        remoteSort: true,
        remoteFilter: true,
        pageSize: 20
    },

    selType: 'rowmodel',


    features: [
    {
        ftype: 'ransack_filters',
        local: false
    }
    ],

    addColumn: function (new_column, relative_position){
        this.planColumns.splice(relative_position, 0, new_column)
    },

    initComponent: function () {
        var self = this;

        Ext.apply(this, {
            columns: this.planColumns,
        });

        self.callParent();

        self.addDocked(Ext.create('Ext.toolbar.Paging', {
            store: self.getStore(),
            dock: 'bottom',
            displayInfo: true
        }));

        self.addListener('afterrender', function () {
            self.filters.createFilters();
        });
    },

    planColumns: [
    {
        dataIndex: 'id',
        header: 'ID',
        readOnly: true,
        hidden: true
    },
    {
        dataIndex: 'marker_symbol',
        header: 'Marker Symbol',
        readOnly: true,
        width: 150,
        filter: {
            type: 'string'
        }
    },
    {
        dataIndex: 'consortium_name',
        header: 'Consortium',
        readOnly: true,
        width: 150,
        filter: {
            type: 'list',
            options: window.CONSORTIUM_OPTIONS
        }
    },
    {
        dataIndex: 'production_centre_name',
        header: 'Production Centre',
        readOnly: true,
      width: 200,
      filter: {
          type: 'list',
            options: window.CENTRE_OPTIONS,
            value: window.USER_PRODUCTION_CENTRE
        }
    },

    {
        dataIndex: 'es_cell_qc_intent',
        header: 'QC ES Cell',
        readOnly: true,
        width: 110,
        xtype: 'boolgridcolumn'
    },
    {
        dataIndex: 'es_cell_mi_attempt_intent',
        header: 'MI ES Cell',
        readOnly: true,
        width: 110,
        xtype: 'boolgridcolumn'
    },
    {
        dataIndex: 'crispr_mi_attempt_intent',
        header: 'MI CRISPR',
        readOnly: true,
        width: 110,
        xtype: 'boolgridcolumn'
    },
    {
        dataIndex: 'mouse_allele_modification_intent',
        header: 'Modify Mouse Allele',
        readOnly: true,
        width: 110,
        xtype: 'boolgridcolumn'
    },
    {
        dataIndex: 'phenotyping_intent',
        header: 'Phenotype',
        readOnly: true,
        width: 110,
        xtype: 'boolgridcolumn'
    }
]
});
