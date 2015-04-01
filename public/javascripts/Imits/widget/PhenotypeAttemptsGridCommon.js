function splitString(prettyPrintDistributionCentres) {
    var distributionCentres = [];
    Ext.Array.each(prettyPrintDistributionCentres.split(', '), function(dc) {
        distributionCentres.push({
            distributionCentre: dc
        });
    });

    return distributionCentres;
}

Ext.define('Imits.widget.PhenotypeAttemptsGridCommon', {
    extend: 'Imits.widget.Grid',

    requires: [
    'Imits.model.PhenotypeAttempt',
    'Imits.widget.SimpleNumberField',
    'Imits.widget.grid.PhenotypeAttemptRansackFiltersFeature',
    'Imits.widget.grid.BoolGridColumn',
    'Imits.Util'
    ],

    title: "Phenotype attempts",
    iconCls: 'icon-grid',
    columnLines: true,

    store: {
        model: 'Imits.model.PhenotypeAttempt',
        autoLoad: true,
        remoteSort: true,
        remoteFilter: true,
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

        Ext.apply(self, {
            columns: self.phenotypeColumns,
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

    addColumn: function (new_column, relative_position){
        this.phenotypeColumns.splice(relative_position, 0, new_column)
    },

    phenotypeColumns: [
    {
        dataIndex: 'id',
        header: 'ID',
        readOnly: true,
        hidden: (Imits.Util.extractValueIfExistent(window.PHENOTYPE_ATTEMPT_SEARCH_PARAMS, 'phenotype_attempt_id') ? false : true),
        filter: {
            type: 'string',
            value: Imits.Util.extractValueIfExistent(window.PHENOTYPE_ATTEMPT_SEARCH_PARAMS, 'phenotype_attempt_id')
        }
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
            options: window.CONSORTIUM_OPTIONS,
            value: Imits.Util.extractValueIfExistent(window.PHENOTYPE_ATTEMPT_SEARCH_PARAMS, 'consortium_name')
        },
        sortable: false
    },
    {
        dataIndex: 'production_centre_name',
        header: 'Production Centre',
        readOnly: true,
        width: 150,
        filter: {
            type: 'list',
            options: window.CENTRE_OPTIONS,
            value: Imits.Util.extractValueIfExistent(window.PHENOTYPE_ATTEMPT_SEARCH_PARAMS, 'production_centre_name')
        },
        sortable: false
    },
    {
        dataIndex: 'marker_symbol',
        header: 'Marker Symbol',
        readOnly: true,
        filter: {
            type: 'string',
            value: Imits.Util.extractValueIfExistent(window.PHENOTYPE_ATTEMPT_SEARCH_PARAMS, 'es_cell_marker_symbol')
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
            options: window.PHENOTYPE_STATUS_OPTIONS,
            value: Imits.Util.extractValueIfExistent(window.PHENOTYPE_ATTEMPT_SEARCH_PARAMS, 'status_name')
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
    },

    // QC Details
    {
        dataIndex: 'qc_southern_blot_result',
        header: 'Southern Blot',
        sortable: false,
        editor: 'qccombo'
    },
    {
        dataIndex: 'qc_five_prime_lr_pcr_result',
        header: 'Five Prime LR PCR',
        sortable: false,
        editor: 'qccombo'
    },
    {
        dataIndex: 'qc_five_prime_cassette_integrity_result',
        header: 'Five Prime Cassette Integrity',
        sortable: false,
        editor: 'qccombo'
    },
    {
        dataIndex: 'qc_tv_backbone_assay_result',
        header: 'TV Backbone Assay',
        sortable: false,
        editor: 'qccombo'
    },
    {
        dataIndex: 'qc_neo_count_qpcr_result',
        header: 'Neo Count QPCR',
        sortable: false,
        editor: 'qccombo'
    },
    {
        dataIndex: 'qc_lacz_count_qpcr_result',
        header: 'Lacz Count QPCR',
        sortable: false,
        editor: 'qccombo'
    },
    {
        dataIndex: 'qc_neo_sr_pcr_result',
        header: 'Neo SR PCR',
        sortable: false,
        editor: 'qccombo'
    },
    {
        dataIndex: 'qc_loa_qpcr_result',
        header: 'LOA QPCR',
        sortable: false,
        editor: 'qccombo'
    },
    {
        dataIndex: 'qc_homozygous_loa_sr_pcr_result',
        header: 'Homozygous LOA SR PCR',
        sortable: false,
        editor: 'qccombo'
    },
    {
        dataIndex: 'qc_lacz_sr_pcr_result',
        header: 'LacZ SR PCR',
        sortable: false,
        editor: 'qccombo'
    },
    {
        dataIndex: 'qc_mutant_specific_sr_pcr_result',
        header: 'Mutant Specific SR PCR',
        sortable: false,
        editor: 'qccombo'
    },
    {
        dataIndex: 'qc_loxp_confirmation_result',
        header: 'LoxP Confirmation',
        sortable: false,
        editor: 'qccombo'
    },
    {
        dataIndex: 'qc_three_prime_lr_pcr_result',
        header: 'Three Prime LR PCR',
        sortable: false,
        editor: 'qccombo'
    },
    {
        dataIndex: 'qc_critical_region_qpcr_result',
        header: 'Critical Region QPCR',
        sortable: false,
        editor: 'qccombo'
    },
    {
        dataIndex: 'qc_loxp_srpcr_result',
        header: 'Loxp SRPCR',
        sortable: false,
        editor: 'qccombo'
    },
    {
        dataIndex: 'qc_loxp_srpcr_and_sequencing_result',
        header: 'Loxp SRPRC and Sequencing',
        sortable: false,
        editor: 'qccombo'
    },
    {
        dataIndex: 'report_to_public',
        header: 'Report to Public',
        xtype: 'boolgridcolumn'
    },
    {
        dataIndex: 'is_active',
        header: 'Active?',
        xtype: 'boolgridcolumn'
    }
    ]
});
