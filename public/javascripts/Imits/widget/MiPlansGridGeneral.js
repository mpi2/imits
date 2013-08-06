Ext.define('Imits.widget.MiPlansGridGeneral', {
    extend: 'Imits.widget.MiPlansGridCommon',

    // extends the MiPlanColumns in MiPlanGridCommon. These column should be independent from the MiPlanGrid (editable grid). columns common to read only grid and editable grid should be added to MiPlanGridCommon.
    additionalColumns: [],

    initComponent: function() {
        grid = this;
        // Adds additional columns
        Ext.Array.each(grid.additionalColumns, function(column) {
            grid.addColumn(column['data'], column['position']);
        });

      this.callParent();
    }
})