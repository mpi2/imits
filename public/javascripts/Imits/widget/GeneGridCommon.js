// gene grid with common fields and method for both the editable gene grid and read only grid
function splitResultString(mi_string) {
    var mis = [];
    var pattern = /^\[(.+)\:(.+)\:(\d+)\]$/;
    Ext.Array.each(mi_string.split('<br/>'), function(mi) {
        var match = pattern.exec(mi);
        mis.push({
            consortium: match[1],
            production_centre: match[2],
            count: match[3]
        });
    });
    return mis;
}

function printMiPlanString(mi_plan) {
    var str = '[' + mi_plan['consortium'];
    if (!Ext.isEmpty(mi_plan['production_centre'])) {
        str = str + ':' + mi_plan['production_centre'];
    }
    if (!Ext.isEmpty(mi_plan['status_name'])) {
        str = str + ':' + mi_plan['status_name'];
    }
    str = str + ']';
    return str;
}


Ext.define('Imits.widget.GeneGridCommon', {
    extend: 'Imits.widget.Grid',
    requires: [
    'Imits.model.Gene',
    'Imits.widget.grid.RansackFiltersFeature',
    'Imits.widget.SimpleCombo',
    'Ext.ux.RowExpander',
    'Ext.selection.CheckboxModel'
    ],
    title: '&nbsp;',
    iconCls: 'icon-grid',
    columnLines: true,
    store: {
        model: 'Imits.model.Gene',
        autoLoad: true,
        remoteSort: true,
        remoteFilter: true,
        pageSize: 20
    },
    selModel: Ext.create('Ext.selection.CheckboxModel'),
    features: [
    {
        ftype: 'ransack_filters',
        local: false
    }
    ],

    initComponent: function() {
        var grid = this;
        Ext.apply(this, {
            columns: grid.geneColumns,
        });
        grid.callParent();
        // Add the bottom (pagination) toolbar
        grid.addDocked(Ext.create('Ext.toolbar.Paging', {
            store: grid.getStore(),
            dock: 'bottom',
            displayInfo: true
        }));
    },

    addColumn: function (new_column, relative_position){
        this.geneColumns.splice(relative_position, 0, new_column)
    },

    // colums to show in the grid common to both the editable and read only grid.
    geneColumns: [
        {
            header: 'Gene',
            dataIndex: 'marker_symbol',
            readOnly: true,
            renderer: function (symbol) {
                return Ext.String.format('<a href="http://www.knockoutmouse.org/martsearch/search?query={0}" target="_blank">{0}</a>', symbol);
            }
        },
        {
            header: '# IKMC Projects',
            dataIndex: 'ikmc_projects_count',
            readOnly: true
        },
        {
            header: '# Clones',
            dataIndex: 'pretty_print_types_of_cells_available',
            readOnly: true,
            sortable: false
        }
]
});
