Ext.define('Imits.widget.MiPlansGridCommon', {
    extend: 'Imits.widget.Grid',

    requires: [
    'Imits.model.MiPlan',
    'Imits.widget.grid.RansackFiltersFeature',
    'Imits.widget.MiPlanEditor'
    ],

    title: 'Plans',
    iconCls: 'icon-grid',
    columnLines: true,

    store: {
        model: 'Imits.model.MiPlan',
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
        this.miPlanColumns.splice(relative_position, 0, new_column)
    },

    initComponent: function () {
      var self = this;

      if(window.CAN_SEE_SUB_PROJECT){
        self.addColumn(
          {
            dataIndex: 'is_bespoke_allele',
            header: 'Bespoke',
            xtype: 'boolgridcolumn',
            width: 60,
            readOnly: true
          },this.miPlanColumns.length
        );
        self.addColumn(
          {
            dataIndex: 'sub_project_name',
            header: 'Sub-Project',
            readOnly: true,
            width: 120,
            filter: {
                type: 'list',
                options: window.SUB_PROJECT_OPTIONS
            }
          },5
      );
      };
        Ext.apply(this, {
            columns: this.miPlanColumns,
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

    miPlanColumns: [
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
        filter: {
            type: 'string'
        }
    },
    {
        dataIndex: 'consortium_name',
        header: 'Consortium',
        readOnly: true,
        width: 100,
        filter: {
            type: 'list',
            options: window.CONSORTIUM_OPTIONS
        }
    },
    {
        dataIndex: 'production_centre_name',
        header: 'Production Centre',
        readOnly: true,
      width: 115,
      filter: {
          type: 'list',
            options: window.CENTRE_OPTIONS,
            value: window.USER_PRODUCTION_CENTRE
        }
    },
    {
        dataIndex: 'status_name',
        header: 'Status',
        readOnly: true,
        flex: 1,
        filter: {
            type: 'list',
            options: window.STATUS_OPTIONS
        }
    },
    {
        dataIndex: 'priority_name',
        header: 'Priority',
        readOnly: true,
        width: 80,
        filter: {
            type: 'list',
            options: window.PRIORITY_OPTIONS
        }
    },
    {
        dataIndex: 'is_conditional_allele',
        header: 'Conditional',
        xtype: 'boolgridcolumn',
        width: 60,
        readOnly: true
    },
    {
        dataIndex: 'is_deletion_allele',
        header: 'Deletion',
        xtype: 'boolgridcolumn',
        width: 60,
        readOnly: true
    },
    {
        dataIndex: 'is_cre_knock_in_allele',
        header: 'Cre Knock-in',
        xtype: 'boolgridcolumn',
        width: 60,
        readOnly: true
    },
    {
        dataIndex: 'is_cre_bac_allele',
        header: 'Cre BAC',
        xtype: 'boolgridcolumn',
        width: 60,
        readOnly: true
    }
]
});
