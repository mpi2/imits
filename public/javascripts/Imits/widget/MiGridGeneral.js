Ext.define('Imits.widget.MiGridGeneral', {
    extend: 'Imits.widget.MiGridCommon',

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
                                textToDisplayArray.push( Ext.String.format('<a href="{0}/open/mi_attempts/{1}#distribution_centres" target="_blank">{2}</a>', window.basePath, miId, distribution_centres[i]) );
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
                    console.log(genotype_confirmed_colony_names);
                    if (genotype_confirmed_colony_names.length > 0 && genotype_confirmed_colony_names[0].length > 0) {
                        for (var i = 0, len = genotype_confirmed_colony_names.length; i < len; i++)
                            {
                              textToDisplayArray.push( Ext.String.format('<a href="{0}/open/phenotype_attempts?q[terms]={2}">({1})</a>', window.basePath, phenotype_attempts_count[i], genotype_confirmed_colony_names[i]) );
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
                header: 'Show In Form',
                dataIndex: 'show_link',
                renderer: function(value, metaData, record) {
                    var miId = record.getId();
                    return Ext.String.format('<a href="{0}/open/mi_attempts/{1}">Show in Form</a>', window.basePath, miId);
                },
                sortable: false
                }
            },
           {'position' : 0, 'data' : {
                header: 'Mouse Production Summary',
                dataIndex: 'mouse_production_summary',
                width: 160,
                renderer: function(value, metaData, record) {
                    var mgi_accession_id = record.get('mgi_accession_id');
                    return Ext.String.format('<a href="https://www.mousephenotype.org/data/genes/{0}#order">View in IMPC Website</a>', mgi_accession_id);
                },
                sortable: false
                }
            }
           ]
    },

    constructor: function(config) {
        grid = this;
        Ext.Object.each(grid.additionalColumns, function(groupName, groupColumns) {
            Ext.Array.each(groupColumns, function(column) {
                grid.addColumnsToGroupedColumns(groupName, column['position'], column['data']);
            })
        });
        this.callParent([config]);
    },

})