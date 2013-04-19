Ext.define('Imits.widget.MiGrid', {
    extend: 'Imits.widget.MiGridCommon',

    // allows grid to be edited.
    plugins: [
    Ext.create('Ext.grid.plugin.RowEditing', {
        autoCancel: false,
        clicksToEdit: 1
    })
    ],
    // extends the groupedColumns in MiGridCommon. These column should be independent from the MiGridGeneral (read only grid). columns common to read only grid and editable grid should be added to MiGridCommon.
    additionalColumns: {
        'common' :
            [
            {'position': 9, 'data': {
                header: 'Distribution Centres',
                dataIndex: 'distribution_centres_formatted_display',
                readOnly: true,
                sortable: false,
                width: 225,
                renderer: function(value, metaData, record){
                    var miId = record.getId();
                    var distribution_centres = record.get('distribution_centres_formatted_display');
                    if (distribution_centres != '') {
                        return Ext.String.format('<a href="{0}/mi_attempts/{1}#distribution_centres" target="_blank">{2}</a>', window.basePath, miId, distribution_centres);
                    } else {
                        return Ext.String.format('{0}', distribution_centres);
                    }
                }
                }
            },
            {'position' : 0, 'data' : {
                header: 'Phenotype',
                dataIndex: 'phenotype_attempt_new_link',
                renderer: function(value, metaData, record){
                    var miId = record.getId();
                    var statusName = record.get('status_name');
                    if (statusName == "Genotype confirmed") {
                        return Ext.String.format('<a href="{0}/mi_attempts/{1}/phenotype_attempts/new">Create</a>', window.basePath, miId);
                    } else {
                        return Ext.String.format('', window.basePath, miId);
                    }
                },
                sortable: false
                }
             },
             {'position' : 0, 'data' : {
                header: 'Edit In Form',
                dataIndex: 'edit_link',
                renderer: function(value, metaData, record) {
                    var miId = record.getId();
                    return Ext.String.format('<a href="{0}/mi_attempts/{1}">Edit in Form</a>', window.basePath, miId);
                },
                sortable: false
                }
            }]
    },

    constructor: function(config) {
        // adds the additional columns to the groupedColumns in MiGridCommon.
        grid = this;
        Ext.Object.each(grid.additionalColumns, function(groupName, groupColumns) {
            Ext.Array.each(groupColumns, function(column) {
                grid.addColumnsToGroupedColumns(groupName, column['position'], column['data']);
            })
        })
        this.callParent([config]);
    },

})









