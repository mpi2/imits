function splitString(prettyPrintDistributionCentres) {
    var distributionCentres = [];
    Ext.Array.each(prettyPrintDistributionCentres.split(', '), function(dc) {
        distributionCentres.push({
            distributionCentre: dc
        });
    });

    return distributionCentres;
}

Ext.define('Imits.widget.PhenotypeAttemptsGrid', {
    extend: 'Imits.widget.Grid',

    requires: [
    'Imits.model.PhenotypeAttempt',
    'Imits.widget.SimpleNumberField',
    'Imits.widget.grid.PhenotypeAttemptRansackFiltersFeature',
    'Imits.widget.grid.BoolGridColumn'
    ],

    title: "Phenotype attempts",
    iconCls: 'icon-grid',
    columnLines: true,

    store: {
        model: 'Imits.model.PhenotypeAttempt',
        autoLoad: true,
        remoteSort: true,
        pageSize: 20
    },

    selType: 'rowmodel',

    features: [
    {
        ftype: 'phenotype_attempt_ransack_filters',
        local: false
    }
    ],

    initComponent: function () {
        var self = this;

        self.callParent();

        self.addDocked(Ext.create('Ext.toolbar.Paging', {
            store: self.getStore(),
            dock: 'bottom',
            displayInfo: true
        }));

    },

    columns: [
    {
        dataIndex: 'id',
        header: 'ID',
        readOnly: true,
        hidden: true
    },
    {
        header: 'Edit In Form',
        dataIndex: 'edit_link',
        renderer: function(value, metaData, record) {
            var miId = record.getId();
            return Ext.String.format('<a href="{0}/phenotype_attempts/{1}">Edit in Form</a>', window.basePath, miId);
        },
        sortable: false
    },
    {
        dataIndex: 'colony_name',
        header: 'Colony Name',
        editor: 'textfield',
        filter: {
            type: 'string'
        }
    },
    {
        dataIndex: 'consortium_name',
        header: 'Consortium',
        readOnly: true,
        width: 115,
        filter: {
            type: 'list',
            options: window.PHENOTYPE_CONSORTIUM_OPTIONS
        }
    },
    {
        dataIndex: 'production_centre_name',
        header: 'Production Centre',
        readOnly: true,
        width: 150,
        filter: {
            type: 'list',
            options: window.PHENOTYPE_CENTRE_OPTIONS
        }
    },
    {
        header: 'Distribution Centres',
        dataIndex: 'distribution_centres_formatted_display',
        readOnly: true,
        sortable: false,
        width: 225,
        renderer: function(value, metaData, record){
          var paId = record.getId();
          var distribution_centres = record.get('distribution_centres_formatted_display');
          if (distribution_centres != '') {
            return Ext.String.format('<a href="{0}/phenotype_attempts/{1}#distribution_centres" target="_blank">{2}</a>', window.basePath, paId, distribution_centres);
            } else {
                return Ext.String.format('{0}', distribution_centres);
              }
          }
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
        dataIndex: 'is_active',
        header: 'Active?',
        readOnly: true,
        width: 55,
        xtype: 'boolgridcolumn',
        filter: {
            type: 'boolean'
        }
    },
    {
        dataIndex: 'status_name',
        header: 'Status',
        readOnly: true,
        filter: {
            type: 'list',
            options: window.PHENOTYPE_STATUS_OPTIONS
        }
    },
    {
        dataIndex: 'rederivation_started',
        header: 'Rederivation started',
        readOnly: true,
        xtype: 'boolgridcolumn',
        width: 115,
        filter: {
            type: 'boolean'
        }
    },
    {
        dataIndex: 'rederivation_complete',
        header: 'Rederivation complete',
        readOnly: true,
        xtype: 'boolgridcolumn',
        width: 120,
        filter: {
            type: 'boolean'
        }
    },
    {
        dataIndex: 'deleter_strain_name',
        header: 'Cre-deleter strain',
        readOnly: true,
        filter: {
            type: 'list',
            options: window.PHENOTYPE_DELETER_STRAIN_OPTIONS
        }
    },
    {
        dataIndex: 'number_of_cre_matings_successful',
        header: '# Cre Matings successful',
        readOnly: true,
        editor: 'simplenumberfield',
        width: 140
    },
    {
        dataIndex: 'phenotyping_started',
        header: 'Phenotyping Started',
        readOnly: true,
        xtype: 'boolgridcolumn',
        width: 115,
        filter: {
            type: 'boolean'
        }
    },
    {
        dataIndex: 'phenotyping_complete',
        header: 'Phenotyping Complete',
        readOnly: true,
        xtype: 'boolgridcolumn',
        width: 120,
        filter: {
            type: 'boolean'
        }
    }
    ]
});
