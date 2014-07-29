Ext.define('Imits.widget.MiGridGeneral', {
    extend: 'Imits.widget.MiGridCommon',

    additionalColumns: {
        'common' :
            [
            {'position': 9, 'data': {
                header: 'Distribution Centres',
                dataIndex: 'distribution_centres_formatted_display',
                readOnly: true,
                sortable: false,
                width: 230,
                renderer: function(value, metaData, record){
                    var miId = record.getId();
                    var distribution_centres = record.get('distribution_centres_formatted_display');
                    if (distribution_centres != '') {
                        return Ext.String.format('<a href="{0}/open/mi_attempts/{1}#distribution_centres" target="_blank">{2}</a>', window.basePath, miId, distribution_centres);
                    } else {
                        return Ext.String.format('{0}', distribution_centres);
                    }
                }
                }
            },
            {'position' : 0, 'data' : {
                header: '# Active Phenotypes',
                dataIndex: 'phenotype_attempts_count',
                readOnly: true,
                sortable: false,
                width: 110,
                renderer: function(value, metaData, record){
                    var miId = record.getId();
                    var phenotypeCount = record.get('phenotype_attempts_count');
                    var geneSymbol = record.get('marker_symbol');
                    var productionCentre = record.get('production_centre_name');
                    var statusName = record.get('status_name');
                    if (statusName == "Genotype confirmed") {
                        if (phenotypeCount != 0) {
                            return Ext.String.format('<a href="{0}/open/phenotype_attempts?q[terms]={1}&q[production_centre_name]={2}">{3}</a>', window.basePath, geneSymbol, productionCentre, phenotypeCount);
                        } else {
                            return '0';
                        }
                    }
                }
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
                    return Ext.String.format('<a href="https://www.mousephenotype.org/data/genes/{0}#allele_tracker_panel_results">View in IMPC Website</a>', mgi_accession_id);
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