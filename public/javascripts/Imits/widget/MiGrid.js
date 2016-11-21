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
            {'position': 7, 'data': {
                header: 'Distribution Centres',
                dataIndex: 'genotype_confirmed_distribution_centres',
                readOnly: true,
                sortable: false,
                width: 230,
                renderer: function(value, metaData, record){
                    var miId = record.getId();
                    var distribution_centres = record.get('genotype_confirmed_distribution_centres').toString().replace('[[', '[').replace(']]', ']').replace('],[', ']\t[').split('\t');
                    var textToDisplayArray = [];
                    var textToDisplay = '';
                    if (distribution_centres.length > 0 && distribution_centres[0].length > 2) {
                        for (var i = 0, len = distribution_centres.length; i < len; i++)
                            {
                            if (distribution_centres != '') {
                                textToDisplayArray.push( Ext.String.format('<a href="{0}/mi_attempts/{1}#distribution_centres" target="_blank">{2}</a>', window.basePath, miId, distribution_centres[i]) );
                            } else {
                                textToDisplayArray.push('');
                            }
                        }
                    }
                    else {
                        textToDisplayArray.push('');
                    }
                    textToDisplay = textToDisplayArray.join('<br><br>');
                    return textToDisplay;
                }}
            },
            {'position' : 6, 'data' : {
                header: '# Active Phenotypes',
                dataIndex: 'phenotype_attempt_new_link',
                width: 115,
                renderer: function(value, metaData, record){
                    var genotype_confirmed_colony_names = record.get('genotyped_confirmed_colony_names').toString().replace('[', '').replace(']', '').split(',');
                    var phenotype_attempts_count = record.get('genotyped_confirmed_colony_phenotype_attempts_count').toString().replace('[', '').replace(']', '').split(',');
                    var textToDisplayArray = [];
                    var textToDisplay = '';
                    if (genotype_confirmed_colony_names.length > 0 && genotype_confirmed_colony_names[0].length > 0) {
                        for (var i = 0, len = genotype_confirmed_colony_names.length; i < len; i++)
                            {
                              textToDisplayArray.push( Ext.String.format('<a href="{0}/phenotype_attempts?q[terms]={2}">({1})</a> / <a href="{0}/colony/{2}/phenotype_attempts/new">Create</a>', window.basePath, phenotype_attempts_count[i], genotype_confirmed_colony_names[i]) );
                            }
                    }
                    else {

                    }
                    textToDisplay = textToDisplayArray.join('<br><br>');
                    return textToDisplay;
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
