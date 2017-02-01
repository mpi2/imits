Ext.define('Imits.data.JsonReader', {
    extend: 'Ext.data.reader.Json',
    alias: null,

    readRecords: function(data) {
        if( !this.getRoot(data) && !Ext.isEmpty(data['id'])  ) {
            data = [data];
        }
        return this.callParent([data]);
    },

    getResponseData: function(response) {
        if(response.request.options.method == 'DELETE' &&
            response.status == 200) {
            return {};
        } else {
            return this.callParent([response]);
        }
    }
});

Ext.define('Imits.data.JsonWriter', {
    extend: 'Ext.data.writer.Json',
    writeAllFields: false,
    write: function(originalRequest) {
        var request = this.callParent([originalRequest]);
        request.params['authenticity_token'] = window.authenticityToken;
        if(request.jsonData[this.root] && request.jsonData[this.root]['id']) {
            delete request.jsonData[this.root]['id'];
        }

        if(request.action === "destroy" && !Ext.isEmpty(request.params)) {
            // Set params as URL parameters if DELETE request instead of passing
            // them through as JSON in the body, or certain proxies complain
            request.url = Ext.urlAppend(request.url, Ext.urlEncode(request.params));
            request.jsonData = null;
            request.params = null;
        }

        return request;
    }
});

Ext.define('Imits.Util', {
    statics: {
        handleErrorResponse: function (response) {
            var errors = Ext.JSON.decode(response.responseText);
            var errorHelper = function () {
                var errorStrings = [];
                if (errors.hasOwnProperty('backtrace')) {
                    delete errors.backtrace;
                }
                Ext.Object.each(errors, function (key, values) {
                    var errorString =
                    Ext.String.capitalize(key).replace(/_/g, " ") +
                    ": ";
                    if (Ext.isString(values)) {
                        errorString += values;
                    } else if (Ext.isArray) {
                        errorString += values.join(", ");
                    }
                    errorStrings.push(Ext.String.htmlEncode(errorString));
                });
                return errorStrings.join("<br/>");
            };
            Ext.MessageBox.show({
                title: 'Error',
                msg: errorHelper(errors),
                icon: Ext.MessageBox.ERROR,
                buttons: Ext.Msg.OK,
                fn: function (buttonid, text, opt) {
                // TODO: Refresh the cell/row that was changed
                }
            });
        },

        extractValueIfExistent: function (object, valueName) {
            if (Ext.isEmpty(object) || !object.hasOwnProperty(valueName)) {
                return undefined;
            }

            var value = object[valueName];

            if (!Ext.isEmpty(value)) {
                return value;
            } else {
                return undefined;
            }
        }

    }
});

Ext.define('Imits.data.Proxy', {
    extend: 'Ext.data.proxy.Rest',
    requires: [
    'Imits.data.JsonWriter',
    'Imits.data.JsonReader',
    'Imits.Util'
    ],

    constructor: function (config) {
        var resource = config.resource;
        var resourcePath =  resource + 's';

        if (config.resourcePath) {
            resourcePath =  config.resourcePath;
        }

        if(open_interface) {
          resource = 'open_' + resource
          resourcePath = 'open/' + resourcePath
        }

        this.callParent([{
            format: 'json',
            url: window.basePath + '/' + resourcePath,
            extraParams: {
                'extended_response': true
            },
            startParam: undefined,
            limitParam: 'per_page',
            sortParam: 'sorts',

            reader: Ext.create('Imits.data.JsonReader', {
                root: resource + 's'
            }),

            writer: Ext.create('Imits.data.JsonWriter', {
                root: resource,
                writeAllFields: false
            }),

            listeners: {
                exception: function (proxy, response, operation) {
                    Imits.Util.handleErrorResponse(response);
                }
            },

            encodeSorters: function(sorters) {
                if (sorters.length === 0) {
                    return "";
                } else {
                    var sorter = sorters[0];
                    return sorter.property + ' ' + sorter.direction.toLowerCase();
                }
            }
        }]);
    }
});

Ext.define('Imits.model.Centre', {
    extend: 'Ext.data.Model',
    requires: ['Imits.data.Proxy'],

    fields: [
    {
        name: 'id',
        type: 'int',
        persist: false
    },
    {
      name: "name"
    },
    {
      name: "contact_name"
    },
    {
      name: "contact_email"
    }
    ],
    proxy: Ext.create('Imits.data.Proxy', {
        resource: 'centre'
    })
})
Ext.define('Imits.model.Contact', {
    extend: 'Ext.data.Model',
    requires: ['Imits.data.Proxy'],

    fields: [
    {
        name: 'id',
        type: 'int',
        persist: false
    },
    {
      name: "email"
    }
    ],
    proxy: Ext.create('Imits.data.Proxy', {
        resource: 'admin_contact',
        resourcePath: 'admin/contacts'
    })
})
Ext.define('Imits.model.Gene', {
    extend: 'Ext.data.Model',
    requires: ['Imits.data.Proxy'],

fields: [
    {
        name: 'id',
        type: 'int',
        readOnly: true
    },

    {
        name: 'marker_symbol',
        readOnly: true
    },

    {
        name: 'mgi_accession_id',
        readOnly: true
    },

    {
        name: 'ikmc_projects_count',
        readOnly: true
    },

    {
        name: 'pretty_print_types_of_cells_available',
        readOnly: true
    },

    {
        name: 'non_assigned_mi_plans',
        readOnly: true
    },

    {
        name: 'assigned_mi_plans',
        readOnly: true
    },

    {
        name: 'pretty_print_aborted_mi_attempts',
        readOnly: true
    },

    {
        name: 'pretty_print_mi_attempts_in_progress',
        readOnly: true
    },

    {
        name: 'pretty_print_mi_attempts_genotype_confirmed',
        readOnly: true
    },

    {
        name: 'pretty_print_phenotype_attempts',
        readOnly: true
    }

    ],
    proxy: Ext.create('Imits.data.Proxy', {
        resource: 'gene'
    })
});

Ext.define('Imits.model.MiAttempt', {
    extend: 'Ext.data.Model',
    requires: ['Imits.data.Proxy'],

    fields: [
    {
        name: 'id',
        type: 'int',
        persist: false
    },
    {
        name: 'es_cell_name',
        persist: false
    },
    {
        name: 'es_cell_marker_symbol',
        persist: false
    },
    {
        name: 'marker_symbol',
        persist: false
    },
    {
        name: 'es_cell_allele_symbol',
        persist: false
    },
    {
        name: 'mi_date',
        type: 'date'
    },
    {
        name: 'status_name',
        persist: false
    },
    {
        name: 'mi_plan_mutagenesis_via_crispr_cas9',
        persist: false
    },
    {
        name: 'colony_name'
    },
    {
        name: 'genotyped_confirmed_colony_names'
    },
    {
        name: 'genotyped_confirmed_colony_phenotype_attempts_count'
    },
    {
        name: 'genotype_confirmed_allele_symbols'
    },
    {
        name: 'genotype_confirmed_distribution_centres'
    },
    {
        name: 'consortium_name'
    },
    {
        name: 'production_centre_name'
    },
    {
        name: 'distribution_centres_attributes'
    },
    {
        name: 'distribution_centres_formatted_display',
        readOnly: true
    },
    {
        name: 'blast_strain_name'
    },
    {
        name: 'total_blasts_injected',
        type: 'int'
    },
    {
        name: 'total_transferred',
        type: 'int'
    },
    {
        name: 'number_surrogates_receiving',
        type: 'int'
    },
    {
        name: 'total_pups_born',
        type: 'int'
    },
    {
        name: 'total_female_chimeras',
        type: 'int'
    },
    {
        name: 'total_male_chimeras',
        type: 'int'
    },
    {
        name: 'total_chimeras',
        type: 'int',
        persist: false
    },
    {
        name: 'number_of_males_with_0_to_39_percent_chimerism',
        type: 'int'
    },
    {
        name: 'number_of_males_with_40_to_79_percent_chimerism',
        type: 'int'
    },
    {
        name: 'number_of_males_with_80_to_99_percent_chimerism',
        type: 'int'
    },
    {
        name: 'number_of_males_with_100_percent_chimerism',
        type: 'int'
    },

    // Chimera Mating Details
    {
        name: 'emma_status'
    },
    {
        name: 'test_cross_strain_name'
    },
    {
        name: 'colony_background_strain_name'
    },
    {
        name: 'date_chimeras_mated',
        type: 'date'
    },
    {
        name: 'number_of_chimera_matings_attempted',
        type: 'int'
    },
    {
        name: 'number_of_chimera_matings_successful',
        type: 'int'
    },
    {
        name: 'number_of_chimeras_with_glt_from_cct',
        type: 'int'
    },
    {
        name: 'number_of_chimeras_with_glt_from_genotyping',
        type: 'int'
    },
    {
        name: 'number_of_chimeras_with_0_to_9_percent_glt',
        type: 'int'
    },
    {
        name: 'number_of_chimeras_with_10_to_49_percent_glt',
        type: 'int'
    },
    {
        name: 'number_of_chimeras_with_50_to_99_percent_glt',
        type: 'int'
    },
    {
        name: 'number_of_chimeras_with_100_percent_glt',
        type: 'int'
    },
    {
        name: 'total_f1_mice_from_matings',
        type: 'int'
    },
    {
        name: 'number_of_cct_offspring',
        type: 'int'
    },
    {
        name: 'number_of_het_offspring',
        type: 'int'
    },
    {
        name: 'number_of_live_glt_offspring',
        type: 'int'
    },
    {
        name: 'mouse_allele_type',
        readOnly: true
    },
    {
        name: 'mouse_allele_symbol',
        readOnly: true
    },

    // QC Details
    {
        name: 'qc_southern_blot_result'
    },
    {
        name: 'qc_five_prime_lr_pcr_result'
    },
    {
        name: 'qc_five_prime_cassette_integrity_result'
    },
    {
        name: 'qc_tv_backbone_assay_result'
    },
    {
        name: 'qc_neo_count_qpcr_result'
    },
    {
        name: 'qc_lacz_count_qpcr_result'
    },
    {
        name: 'qc_neo_sr_pcr_result'
    },
    {
        name: 'qc_loa_qpcr_result'
    },
    {
        name: 'qc_homozygous_loa_sr_pcr_result'
    },
    {
        name: 'qc_lacz_sr_pcr_result'
    },
    {
        name: 'qc_mutant_specific_sr_pcr_result'
    },
    {
        name: 'qc_loxp_confirmation_result'
    },
    {
        name: 'qc_three_prime_lr_pcr_result'
    },
    {
        name: 'qc_critical_region_qpcr_result'
    },
    {
        name: 'qc_loxp_srpcr_result'
    },
    {
        name: 'qc_loxp_srpcr_and_sequencing_result'
    },
    {
        name: 'report_to_public',
        type: 'boolean'
    },
    {
        name: 'is_active',
        type: 'boolean'
    },
    {
        name: 'is_released_from_genotyping',
        type: 'boolean'
    },
    {   name: 'phenotype_attempts_count',
        type: 'int',
        readOnly: true,
        persist: false
    },
    {
        name: 'mi_plan_id',
        type: 'int'
    },
    {
        name: 'mgi_accession_id'
    },

    // Crispr transfer details
    {
        name: 'crsp_total_embryos_injected',
        type: 'int'
    },
    {
        name: 'crsp_total_embryos_survived',
        type: 'int'
    },
    {
        name: 'crsp_total_transfered',
        type: 'int'
    },

    // Crispr Founder Details
    {
        name: 'crsp_no_founder_pups',
        type: 'int'
    },
    {
        name: 'founder_pcr_num_assays',
        type: 'int'
    },
    {
        name: 'founder_pcr_num_positive_results',
        type: 'int'
    },
    {
        name: 'founder_surveyor_num_assays',
        type: 'int'
    },
    {
        name: 'founder_surveyor_num_positive_results',
        type: 'int'
    },
    {
        name: 'founder_t7en1_num_assays',
        type: 'int'
    },
    {
        name: 'founder_t7en1_num_positive_results',
        type: 'int'
    },
    {
        name: 'founder_loa_num_assays',
        type: 'int'
    },
    {
        name: 'founder_loa_num_positive_results',
        type: 'int'
    },
    {
        name: 'crsp_total_num_mutant_founders',
        type: 'int'
    },
    {
        name: 'crsp_num_founders_selected_for_breading',
        type: 'int'
    },

    ],

    proxy: Ext.create('Imits.data.Proxy', {
        resource: 'mi_attempt'
    })
});

Ext.define('Imits.model.MiPlan', {
    extend: 'Ext.data.Model',
    requires: ['Imits.data.Proxy'],

    fields: [
    {
        name: 'id',
        type: 'int',
        persist: false
    },
    {
        name: 'marker_symbol'
    },
    {
        name: 'consortium_name'
    },
    {
        name: 'production_centre_name'
    },
    {
        name: 'status_name'
    },
    {
        name: 'priority_name'
    },
    {
        name: 'sub_project_name'
    },
    {
        name: 'number_of_es_cells_received'
    },
    {
        name: 'es_cells_received_on',
        type: 'date'
    },
    {
        name: 'es_cells_received_from_name'
    },
    {
        name: 'number_of_es_cells_starting_qc'
    },
    {
        name: 'number_of_es_cells_passing_qc'
    },
    {
        name: 'withdrawn',
        defaultValue: false
    },
    {
        name: 'is_active',
        defaultValue: true
    },
    {
        name: 'is_bespoke_allele',
        defaultValue: false
    },
    {
        name: 'es_qc_comment_name'
    },
    {
        name: 'completion_note'
    },
    {
        name: 'mutagenesis_via_crispr_cas9',
        defaultValue: false
    },
    {
        name: 'phenotype_only',
        defaultValue: false
    },
    {
        name: 'is_conditional_allele',
        defaultValue: false
    },
    {
        name: 'recovery',
        defaultValue: false
    },
    {
        name: 'is_deletion_allele',
        defaultValue: false
    },
    {
        name: 'is_cre_knock_in_allele',
        defaultValue: false
    },
    {
        name: 'is_cre_bac_allele',
        defaultValue: false
    },
    {
        name: 'is_conditional_allele',
        defaultValue: false
    },
    {
        name: 'conditional_tm1c',
        defaultValue: false
    },
    {
        name: 'point_mutation',
        defaultValue: false
    },
    {
        name: 'conditional_point_mutation',
        defaultValue: false
    },
    {
        name: 'allele_symbol_superscript',
        defaultValue: false
    },
    {
        name: 'ignore_available_mice',
        defaultValue: false
    },
    {
        name: 'comment'
    },
    {
        name: 'mi_attempts_count',
        readOnly: true,
        persist: false
    },
    {
        name: 'phenotype_attempts_count',
        readOnly: true,
        persist: false
    }
    ],

    proxy: Ext.create('Imits.data.Proxy', {
        resource: 'mi_plan'
    })
});

Ext.define('MiPlanListViewModel', {
    extend: 'Ext.data.Model',
    fields: ['id', 'consortium_name', 'production_centre_name', 'sub_project_name', 'is_conditional_allele', 'conditional_tm1c', 'is_deletion_allele', 'is_cre_knock_in_allele', 'is_cre_bac_allele', 'point_mutation', 'conditional_point_mutation', 'phenotype_only', 'is_active']
});
Ext.define('Imits.model.Notification', {
    extend: 'Ext.data.Model',
    requires: ['Imits.data.Proxy'],

    fields: [
    {
        name: 'id',
        type: 'int',
        persist: false
    },
    {
      name: "contact_id"
    },
    {
      name: "contact_email"
    },
    {
      name: "gene_id"
    },
    {
      name: "gene_marker_symbol"
    },
    {
      name: "welcome_email_sent"
    },
    {
      name: "last_email_sent"
    },
    {
      name: "welcome_email"
    },
    {
      name: "last_email"
    },
    {
      name: "updated_at"
    }
    ],
    proxy: Ext.create('Imits.data.Proxy', {
        resource: 'admin_notification',
        resourcePath: 'admin/notifications'
    })
})
Ext.define('Imits.model.PhenotypeAttempt', {
    extend: 'Ext.data.Model',
    requires: ['Imits.data.Proxy'],

    fields: [
    {
        name: 'id',
        type: 'int',
        persist: false
    },
    {
        name: 'colony_name'
    },
    {
        name: 'consortium_name'
    },
    {
        name: 'production_centre_name'
    },
    {
        name: 'distribution_centres_formatted_display',
        readOnly: true
    },
    {
        name: 'mi_attempt_colony_name',
        readOnly: true,
        persist: false
    },
    {
        name: 'marker_symbol'
    },
    {
        name: 'is_active'
    },
    {
        name: 'report_to_public'
    },
    {
        name: 'status_name',
        persist: false,
        readOnly: true
    },
    {
        name: 'rederivation_started'
    },
    {
        name: 'rederivation_complete'
    },
    {
        name: 'deleter_strain_name'
    },
    {
        name: 'number_of_cre_matings_successful'
    },
    {
        name: 'phenotyping_started'
    },
    {
        name: 'phenotyping_complete'
    },
    {
        name: 'mi_plan_id',
        type: 'int'
    },
    {
        name: 'mgi_accession_id'
    },

    // QC Details
    'qc_southern_blot_result',
    'qc_five_prime_lr_pcr_result',
    'qc_five_prime_cassette_integrity_result',
    'qc_tv_backbone_assay_result',
    'qc_neo_count_qpcr_result',
    'qc_lacz_count_qpcr_result',
    'qc_neo_sr_pcr_result',
    'qc_loa_qpcr_result',
    'qc_homozygous_loa_sr_pcr_result',
    'qc_lacz_sr_pcr_result',
    'qc_mutant_specific_sr_pcr_result',
    'qc_loxp_confirmation_result',
    'qc_three_prime_lr_pcr_result',
    'qc_critical_region_qpcr_result',
    'qc_loxp_srpcr_result',
    'qc_loxp_srpcr_and_sequencing_result'

    ],

    proxy: Ext.create('Imits.data.Proxy', {
        resource: 'phenotype_attempt'
    })
});

Ext.define('Imits.model.ProductionGoal', {
    extend: 'Ext.data.Model',
    requires: ['Imits.data.Proxy'],

    fields: [
    {
        name: 'id',
        type: 'int',
        persist: false
    },
    {
        name: 'consortium_name'
    },
    {
        name: 'year'
    },
    {
        name: 'month'
    },
    {
        name: 'mi_goal'
    },
    {
        name: 'gc_goal'
    },
    {
        name: 'crispr_mi_goal'
    },
    {
        name: 'crispr_gc_goal'
    }

    ],

    proxy: Ext.create('Imits.data.Proxy', {
        resource: 'production_goal'
    })
});

Ext.define('Imits.model.SolrUpdateQueueItem', {
    extend: 'Ext.data.Model',
    requires: ['Imits.data.Proxy'],

    fields: [
    {
        name: 'id',
        type: 'int',
        persist: false
    },
    {
        name: 'reference'
    },
    {
        name: 'action'
    },
    {
        name: 'created_at'
    }
    ],

    proxy: Ext.create('Imits.data.Proxy', {
        resource: 'solr_update_queue_item',
        resourcePath: 'solr_update/queue/items'
    })
});

Ext.define('Imits.model.Strain', {
    extend: 'Ext.data.Model',
    requires: ['Imits.data.Proxy'],

    fields: [
    {
        name: 'id',
        type: 'int',
        persist: false
    },
    {
      name: "name"
    },
    {
      name: "mgi_strain_accession_id"
    },
    {
      name: "mgi_strain_name"
    }
    ],
    proxy: Ext.create('Imits.data.Proxy', {
        resource: 'strain'
    })
})

Ext.define('Imits.model.TrackingGoal', {
    extend: 'Ext.data.Model',
    requires: ['Imits.data.Proxy'],

    fields: [
    {
        name: 'id',
        type: 'int',
        persist: false
    },
    {
        name: 'consortium_name'
    },
    {
        name: 'production_centre_name'
    },
    {
        name: 'year'
    },
    {
        name: 'month'
    },
    {
        name: 'goal'
    },
    {
        name: 'crispr_goal'
    },
    {
        name: 'goal_type'
    },
    {
        name: 'no_consortium_id',
        readOnly: true,
        persist: false
    }
    ],


    proxy: Ext.create('Imits.data.Proxy', {
        resource: 'tracking_goal'
    })
});

Ext.define('Imits.widget.ManageResizeWithBrowserFrame', {
    manageResize: function() {
        var windowHeight = window.innerHeight - 30;
        if(!windowHeight) {
            windowHeight = document.documentElement.clientHeight - 30;
        }
        var newGridHeight = windowHeight - this.getEl().getTop();
        if(newGridHeight <= 250) {
            newGridHeight = 500;
        }
        this.setHeight(newGridHeight);
        this.setWidth(this.getEl().up('div').getWidth() - 1);
        this.doLayout();
    }
});

Ext.define('Imits.widget.Grid', {
    extend: 'Ext.grid.Panel',

    mixins: [
        'Imits.widget.ManageResizeWithBrowserFrame'
    ],

    reloadStore: function() {
        var store = this.getStore();
        store.sync();
        store.load();
    }
});

/**
 * @class Ext.ux.grid.menu.ListMenu
 * @extends Ext.menu.Menu
 * This is a supporting class for {@link Ext.ux.grid.filter.ListFilter}.
 * Although not listed as configuration options for this class, this class
 * also accepts all configuration options from {@link Ext.ux.grid.filter.ListFilter}.
 */
Ext.define('Ext.ux.grid.menu.ListMenu', {
    extend: 'Ext.menu.Menu',

    /**
     * @cfg {String} labelField
     * Defaults to 'text'.
     */
    labelField :  'text',
    /**
     * @cfg {String} paramPrefix
     * Defaults to 'Loading...'.
     */
    loadingText : 'Loading...',
    /**
     * @cfg {Boolean} loadOnShow
     * Defaults to true.
     */
    loadOnShow : true,
    /**
     * @cfg {Boolean} single
     * Specify true to group all items in this list into a single-select
     * radio button group. Defaults to false.
     */
    single : false,

    constructor : function (cfg) {
        var me = this,
            options,
            i,
            len,
            value;
            
        me.selected = [];
        me.addEvents(
            /**
             * @event checkchange
             * Fires when there is a change in checked items from this list
             * @param {Object} item Ext.menu.CheckItem
             * @param {Object} checked The checked value that was set
             */
            'checkchange'
        );

        me.callParent([cfg = cfg || {}]);

        if(!cfg.store && cfg.options) {
            options = [];
            for(i = 0, len = cfg.options.length; i < len; i++){
                value = cfg.options[i];
                switch(Ext.type(value)){
                    case 'array':  options.push(value); break;
                    case 'object': options.push([value.id, value[me.labelField]]); break;
                    case 'string': options.push([value, value]); break;
                }
            }

            me.store = Ext.create('Ext.data.ArrayStore', {
                fields: ['id', me.labelField],
                data:   options,
                listeners: {
                    load: me.onLoad,
                    scope:  me
                }
            });
            me.loaded = true;
            me.autoStore = true;
        } else {
            me.add({
                text: me.loadingText,
                iconCls: 'loading-indicator'
            });
            me.store.on('load', me.onLoad, me);
        }
    },

    destroy : function () {
        var me = this,
            store = me.store;
            
        if (store) {
            if (me.autoStore) {
                store.destroyStore();
            } else {
                store.un('unload', me.onLoad, me);
            }
        }
        me.callParent();
    },

    /**
     * Lists will initially show a 'loading' item while the data is retrieved from the store.
     * In some cases the loaded data will result in a list that goes off the screen to the
     * right (as placement calculations were done with the loading item). This adapter will
     * allow show to be called with no arguments to show with the previous arguments and
     * thus recalculate the width and potentially hang the menu from the left.
     */
    show : function () {
        if (this.loadOnShow && !this.loaded && !this.store.loading) {
            this.store.load();
        }
        this.callParent();
    },

    /** @private */
    onLoad : function (store, records) {
        var me = this,
            gid, itemValue, i, len,
            listeners = {
                checkchange: me.checkChange,
                scope: me
            };

        Ext.suspendLayouts();
        me.removeAll(true);

        gid = me.single ? Ext.id() : null;
        for (i = 0, len = records.length; i < len; i++) {
            itemValue = records[i].get('id');
            me.add(Ext.create('Ext.menu.CheckItem', {
                text: records[i].get(me.labelField),
                group: gid,
                checked: Ext.Array.contains(me.selected, itemValue),
                hideOnClick: false,
                value: itemValue,
                listeners: listeners
            }));
        }

        me.loaded = true;
        Ext.resumeLayouts(true);
        me.fireEvent('load', me, records);
    },

    /**
     * Get the selected items.
     * @return {Array} selected
     */
    getSelected : function () {
        return this.selected;
    },

    /** @private */
    setSelected : function (value) {
        value = this.selected = [].concat(value);

        if (this.loaded) {
            this.items.each(function(item){
                item.setChecked(false, true);
                for (var i = 0, len = value.length; i < len; i++) {
                    if (item.value == value[i]) {
                        item.setChecked(true, true);
                    }
                }
            }, this);
        }
    },

    /**
     * Handler for the 'checkchange' event from an check item in this menu
     * @param {Object} item Ext.menu.CheckItem
     * @param {Object} checked The checked value that was set
     */
    checkChange : function (item, checked) {
        var value = [];
        this.items.each(function(item){
            if (item.checked) {
                value.push(item.value);
            }
        },this);
        this.selected = value;

        this.fireEvent('checkchange', item, checked);
    }
});

/**
 * @class Ext.ux.grid.menu.RangeMenu
 * @extends Ext.menu.Menu
 * Custom implementation of {@link Ext.menu.Menu} that has preconfigured items for entering numeric
 * range comparison values: less-than, greater-than, and equal-to. This is used internally
 * by {@link Ext.ux.grid.filter.NumericFilter} to create its menu.
 */
Ext.define('Ext.ux.grid.menu.RangeMenu', {
    extend: 'Ext.menu.Menu',

    /**
     * @cfg {String} fieldCls
     * The Class to use to construct each field item within this menu
     * Defaults to:<pre>
     * fieldCls : Ext.form.field.Number
     * </pre>
     */
    fieldCls : 'Ext.form.field.Number',

    /**
     * @cfg {Object} fieldCfg
     * The default configuration options for any field item unless superseded
     * by the <code>{@link #fields}</code> configuration.
     * Defaults to:<pre>
     * fieldCfg : {}
     * </pre>
     * Example usage:
     * <pre><code>
fieldCfg : {
    width: 150,
},
     * </code></pre>
     */

    /**
     * @cfg {Object} fields
     * The field items may be configured individually
     * Defaults to <tt>undefined</tt>.
     * Example usage:
     * <pre><code>
fields : {
    gt: { // override fieldCfg options
        width: 200,
        fieldCls: Ext.ux.form.CustomNumberField // to override default {@link #fieldCls}
    }
},
     * </code></pre>
     */

    /**
     * @cfg {Object} itemIconCls
     * The itemIconCls to be applied to each comparator field item.
     * Defaults to:<pre>
itemIconCls : {
    gt : 'ux-rangemenu-gt',
    lt : 'ux-rangemenu-lt',
    eq : 'ux-rangemenu-eq'
}
     * </pre>
     */
    itemIconCls : {
        gt : 'ux-rangemenu-gt',
        lt : 'ux-rangemenu-lt',
        eq : 'ux-rangemenu-eq'
    },

    /**
     * @cfg {Object} fieldLabels
     * Accessible label text for each comparator field item. Can be overridden by localization
     * files. Defaults to:<pre>
fieldLabels : {
     gt: 'Greater Than',
     lt: 'Less Than',
     eq: 'Equal To'
}</pre>
     */
    fieldLabels: {
        gt: 'Greater Than',
        lt: 'Less Than',
        eq: 'Equal To'
    },

    /**
     * @cfg {Object} menuItemCfgs
     * Default configuration options for each menu item
     * Defaults to:<pre>
menuItemCfgs : {
    emptyText: 'Enter Filter Text...',
    selectOnFocus: true,
    width: 125
}
     * </pre>
     */
    menuItemCfgs : {
        emptyText: 'Enter Number...',
        selectOnFocus: false,
        width: 155
    },

    /**
     * @cfg {Array} menuItems
     * The items to be shown in this menu.  Items are added to the menu
     * according to their position within this array. Defaults to:<pre>
     * menuItems : ['lt','gt','-','eq']
     * </pre>
     */
    menuItems : ['lt', 'gt', '-', 'eq'],


    constructor : function (config) {
        var me = this,
            fields, fieldCfg, i, len, item, cfg, Cls;

        me.callParent(arguments);

        fields = me.fields = me.fields || {};
        fieldCfg = me.fieldCfg = me.fieldCfg || {};
        
        me.addEvents(
            /**
             * @event update
             * Fires when a filter configuration has changed
             * @param {Ext.ux.grid.filter.Filter} this The filter object.
             */
            'update'
        );
      
        me.updateTask = Ext.create('Ext.util.DelayedTask', me.fireUpdate, me);
    
        for (i = 0, len = me.menuItems.length; i < len; i++) {
            item = me.menuItems[i];
            if (item !== '-') {
                // defaults
                cfg = {
                    itemId: 'range-' + item,
                    enableKeyEvents: true,
                    hideLabel: false,
                    fieldLabel: me.iconTpl.apply({
                        cls: me.itemIconCls[item] || 'no-icon',
                        text: me.fieldLabels[item] || '',
                        src: Ext.BLANK_IMAGE_URL
                    }),
                    labelSeparator: '',
                    labelWidth: 29,
                    labelStyle: 'position: relative;',
                    listeners: {
                        scope: me,
                        change: me.onInputChange,
                        keyup: me.onInputKeyUp,
                        el: {
                            click: function(e) {
                                e.stopPropagation();
                            }
                        }
                    },
                    activate: Ext.emptyFn,
                    deactivate: Ext.emptyFn
                };
                Ext.apply(
                    cfg,
                    // custom configs
                    Ext.applyIf(fields[item] || {}, fieldCfg[item]),
                    // configurable defaults
                    me.menuItemCfgs
                );
                Cls = cfg.fieldCls || me.fieldCls;
                item = fields[item] = Ext.create(Cls, cfg);
            }
            me.add(item);
        }
    },

    /**
     * @private
     * called by this.updateTask
     */
    fireUpdate : function () {
        this.fireEvent('update', this);
    },
    
    /**
     * Get and return the value of the filter.
     * @return {String} The value of this filter
     */
    getValue : function () {
        var result = {}, key, field;
        for (key in this.fields) {
            field = this.fields[key];
            if (field.isValid() && field.getValue() !== null) {
                result[key] = field.getValue();
            }
        }
        return result;
    },
  
    /**
     * Set the value of this menu and fires the 'update' event.
     * @param {Object} data The data to assign to this menu
     */	
    setValue : function (data) {
        var me = this,
            key,
            field;

        for (key in me.fields) {
            
            // Prevent field's change event from tiggering a Store filter. The final upate event will do that
            field = me.fields[key];
            field.suspendEvents();
            field.setValue(key in data ? data[key] : '');
            field.resumeEvents();
        }

        // Trigger the filering of the Store
        me.fireEvent('update', me);
    },

    /**  
     * @private
     * Handler method called when there is a keyup event on an input
     * item of this menu.
     */
    onInputKeyUp: function(field, e) {
        if (e.getKey() === e.RETURN && field.isValid()) {
            e.stopEvent();
            this.hide();
        }
    },

    /**
     * @private
     * Handler method called when the user changes the value of one of the input
     * items in this menu.
     */
    onInputChange: function(field) {
        var me = this,
            fields = me.fields,
            eq = fields.eq,
            gt = fields.gt,
            lt = fields.lt;

        if (field == eq) {
            if (gt) {
                gt.setValue(null);
            }
            if (lt) {
                lt.setValue(null);
            }
        }
        else {
            eq.setValue(null);
        }

        // restart the timer
        this.updateTask.delay(this.updateBuffer);
    }
}, function() {

    /**
     * @cfg {Ext.XTemplate} iconTpl
     * A template for generating the label for each field in the menu
     */
    this.prototype.iconTpl = Ext.create('Ext.XTemplate',
        '<img src="{src}" alt="{text}" class="' + Ext.baseCSSPrefix + 'menu-item-icon ux-rangemenu-icon {cls}" />'
    );

});

/**
 * @class Ext.ux.grid.filter.Filter
 * @extends Ext.util.Observable
 * Abstract base class for filter implementations.
 */
Ext.define('Ext.ux.grid.filter.Filter', {
    extend: 'Ext.util.Observable',

    /**
     * @cfg {Boolean} active
     * Indicates the initial status of the filter (defaults to false).
     */
    active : false,
    /**
     * True if this filter is active.  Use setActive() to alter after configuration.
     * @type Boolean
     * @property active
     */
    /**
     * @cfg {String} dataIndex
     * The {@link Ext.data.Store} dataIndex of the field this filter represents.
     * The dataIndex does not actually have to exist in the store.
     */
    dataIndex : null,
    /**
     * The filter configuration menu that will be installed into the filter submenu of a column menu.
     * @type Ext.menu.Menu
     * @property
     */
    menu : null,
    /**
     * @cfg {Number} updateBuffer
     * Number of milliseconds to wait after user interaction to fire an update. Only supported
     * by filters: 'list', 'numeric', and 'string'. Defaults to 500.
     */
    updateBuffer : 500,

    constructor : function (config) {
        Ext.apply(this, config);

        this.addEvents(
            /**
             * @event activate
             * Fires when an inactive filter becomes active
             * @param {Ext.ux.grid.filter.Filter} this
             */
            'activate',
            /**
             * @event deactivate
             * Fires when an active filter becomes inactive
             * @param {Ext.ux.grid.filter.Filter} this
             */
            'deactivate',
            /**
             * @event serialize
             * Fires after the serialization process. Use this to attach additional parameters to serialization
             * data before it is encoded and sent to the server.
             * @param {Array/Object} data A map or collection of maps representing the current filter configuration.
             * @param {Ext.ux.grid.filter.Filter} filter The filter being serialized.
             */
            'serialize',
            /**
             * @event update
             * Fires when a filter configuration has changed
             * @param {Ext.ux.grid.filter.Filter} this The filter object.
             */
            'update'
        );
        Ext.ux.grid.filter.Filter.superclass.constructor.call(this);

        this.menu = this.createMenu(config);
        this.init(config);
        if(config && config.value){
            this.setValue(config.value);
            this.setActive(config.active !== false, true);
            delete config.value;
        }
    },

    /**
     * Destroys this filter by purging any event listeners, and removing any menus.
     */
    destroy : function(){
        if (this.menu){
            this.menu.destroy();
        }
        this.clearListeners();
    },

    /**
     * Template method to be implemented by all subclasses that is to
     * initialize the filter and install required menu items.
     * Defaults to Ext.emptyFn.
     */
    init : Ext.emptyFn,

    /**
     * @private @override
     * Creates the Menu for this filter.
     * @param {Object} config Filter configuration
     * @return {Ext.menu.Menu}
     */
    createMenu: function(config) {
        return Ext.create('Ext.menu.Menu', config);
    },

    /**
     * Template method to be implemented by all subclasses that is to
     * get and return the value of the filter.
     * Defaults to Ext.emptyFn.
     * @return {Object} The 'serialized' form of this filter
     * @methodOf Ext.ux.grid.filter.Filter
     */
    getValue : Ext.emptyFn,

    /**
     * Template method to be implemented by all subclasses that is to
     * set the value of the filter and fire the 'update' event.
     * Defaults to Ext.emptyFn.
     * @param {Object} data The value to set the filter
     * @methodOf Ext.ux.grid.filter.Filter
     */
    setValue : Ext.emptyFn,

    /**
     * Template method to be implemented by all subclasses that is to
     * return <tt>true</tt> if the filter has enough configuration information to be activated.
     * Defaults to <tt>return true</tt>.
     * @return {Boolean}
     */
    isActivatable : function(){
        return true;
    },

    /**
     * Template method to be implemented by all subclasses that is to
     * get and return serialized filter data for transmission to the server.
     * Defaults to Ext.emptyFn.
     */
    getSerialArgs : Ext.emptyFn,

    /**
     * Template method to be implemented by all subclasses that is to
     * validates the provided Ext.data.Record against the filters configuration.
     * Defaults to <tt>return true</tt>.
     * @param {Ext.data.Record} record The record to validate
     * @return {Boolean} true if the record is valid within the bounds
     * of the filter, false otherwise.
     */
    validateRecord : function(){
        return true;
    },

    /**
     * Returns the serialized filter data for transmission to the server
     * and fires the 'serialize' event.
     * @return {Object/Array} An object or collection of objects containing
     * key value pairs representing the current configuration of the filter.
     * @methodOf Ext.ux.grid.filter.Filter
     */
    serialize : function(){
        var args = this.getSerialArgs();
        this.fireEvent('serialize', args, this);
        return args;
    },

    /** @private */
    fireUpdate : function(){
        if (this.active) {
            this.fireEvent('update', this);
        }
        this.setActive(this.isActivatable());
    },

    /**
     * Sets the status of the filter and fires the appropriate events.
     * @param {Boolean} active        The new filter state.
     * @param {Boolean} suppressEvent True to prevent events from being fired.
     * @methodOf Ext.ux.grid.filter.Filter
     */
    setActive : function(active, suppressEvent){
        if(this.active != active){
            this.active = active;
            if (suppressEvent !== true) {
                this.fireEvent(active ? 'activate' : 'deactivate', this);
            }
        }
    }
});

/**
 * @class Ext.ux.grid.filter.BooleanFilter
 * @extends Ext.ux.grid.filter.Filter
 * Boolean filters use unique radio group IDs (so you can have more than one!)
 * <p><b><u>Example Usage:</u></b></p>
 * <pre><code>
var filters = Ext.create('Ext.ux.grid.GridFilters', {
    ...
    filters: [{
        // required configs
        type: 'boolean',
        dataIndex: 'visible'

        // optional configs
        defaultValue: null, // leave unselected (false selected by default)
        yesText: 'Yes',     // default
        noText: 'No'        // default
    }]
});
 * </code></pre>
 */
Ext.define('Ext.ux.grid.filter.BooleanFilter', {
    extend: 'Ext.ux.grid.filter.Filter',
    alias: 'gridfilter.boolean',

	/**
	 * @cfg {Boolean} defaultValue
	 * Set this to null if you do not want either option to be checked by default. Defaults to false.
	 */
	defaultValue : false,
	/**
	 * @cfg {String} yesText
	 * Defaults to 'Yes'.
	 */
	yesText : 'Yes',
	/**
	 * @cfg {String} noText
	 * Defaults to 'No'.
	 */
	noText : 'No',

    /**
     * @private
     * Template method that is to initialize the filter and install required menu items.
     */
    init : function (config) {
        var gId = Ext.id();
		this.options = [
			Ext.create('Ext.menu.CheckItem', {text: this.yesText, group: gId, checked: this.defaultValue === true}),
			Ext.create('Ext.menu.CheckItem', {text: this.noText, group: gId, checked: this.defaultValue === false})];

		this.menu.add(this.options[0], this.options[1]);

		for(var i=0; i<this.options.length; i++){
			this.options[i].on('click', this.fireUpdate, this);
			this.options[i].on('checkchange', this.fireUpdate, this);
		}
	},

    /**
     * @private
     * Template method that is to get and return the value of the filter.
     * @return {String} The value of this filter
     */
    getValue : function () {
		return this.options[0].checked;
	},

    /**
     * @private
     * Template method that is to set the value of the filter.
     * @param {Object} value The value to set the filter
     */
	setValue : function (value) {
		this.options[value ? 0 : 1].setChecked(true);
	},

    /**
     * @private
     * Template method that is to get and return serialized filter data for
     * transmission to the server.
     * @return {Object/Array} An object or collection of objects containing
     * key value pairs representing the current configuration of the filter.
     */
    getSerialArgs : function () {
		var args = {type: 'boolean', value: this.getValue()};
		return args;
	},

    /**
     * Template method that is to validate the provided Ext.data.Record
     * against the filters configuration.
     * @param {Ext.data.Record} record The record to validate
     * @return {Boolean} true if the record is valid within the bounds
     * of the filter, false otherwise.
     */
    validateRecord : function (record) {
		return record.get(this.dataIndex) == this.getValue();
	}
});

/**
 * @class Ext.ux.grid.filter.DateFilter
 * @extends Ext.ux.grid.filter.Filter
 * Filter by a configurable Ext.picker.DatePicker menu
 * <p><b><u>Example Usage:</u></b></p>
 * <pre><code>
var filters = Ext.create('Ext.ux.grid.GridFilters', {
    ...
    filters: [{
        // required configs
        type: 'date',
        dataIndex: 'dateAdded',

        // optional configs
        dateFormat: 'm/d/Y',  // default
        beforeText: 'Before', // default
        afterText: 'After',   // default
        onText: 'On',         // default
        pickerOpts: {
            // any DatePicker configs
        },

        active: true // default is false
    }]
});
 * </code></pre>
 */
Ext.define('Ext.ux.grid.filter.DateFilter', {
    extend: 'Ext.ux.grid.filter.Filter',
    alias: 'gridfilter.date',
    uses: ['Ext.picker.Date', 'Ext.menu.Menu'],

    /**
     * @cfg {String} afterText
     * Defaults to 'After'.
     */
    afterText : 'After',
    /**
     * @cfg {String} beforeText
     * Defaults to 'Before'.
     */
    beforeText : 'Before',
    /**
     * @cfg {Object} compareMap
     * Map for assigning the comparison values used in serialization.
     */
    compareMap : {
        before: 'lt',
        after:  'gt',
        on:     'eq'
    },
    /**
     * @cfg {String} dateFormat
     * The date format to return when using getValue.
     * Defaults to 'm/d/Y'.
     */
    dateFormat : 'm/d/Y',

    /**
     * @cfg {Date} maxDate
     * Allowable date as passed to the Ext.DatePicker
     * Defaults to undefined.
     */
    /**
     * @cfg {Date} minDate
     * Allowable date as passed to the Ext.DatePicker
     * Defaults to undefined.
     */
    /**
     * @cfg {Array} menuItems
     * The items to be shown in this menu
     * Defaults to:<pre>
     * menuItems : ['before', 'after', '-', 'on'],
     * </pre>
     */
    menuItems : ['before', 'after', '-', 'on'],

    /**
     * @cfg {Object} menuItemCfgs
     * Default configuration options for each menu item
     */
    menuItemCfgs : {
        selectOnFocus: true,
        width: 125
    },

    /**
     * @cfg {String} onText
     * Defaults to 'On'.
     */
    onText : 'On',

    /**
     * @cfg {Object} pickerOpts
     * Configuration options for the date picker associated with each field.
     */
    pickerOpts : {},

    /**
     * @private
     * Template method that is to initialize the filter and install required menu items.
     */
    init : function (config) {
        var me = this,
            pickerCfg, i, len, item, cfg;

        pickerCfg = Ext.apply(me.pickerOpts, {
            xtype: 'datepicker',
            minDate: me.minDate,
            maxDate: me.maxDate,
            format:  me.dateFormat,
            listeners: {
                scope: me,
                select: me.onMenuSelect
            }
        });

        me.fields = {};
        for (i = 0, len = me.menuItems.length; i < len; i++) {
            item = me.menuItems[i];
            if (item !== '-') {
                cfg = {
                    itemId: 'range-' + item,
                    text: me[item + 'Text'],
                    menu: Ext.create('Ext.menu.Menu', {
                        items: [
                            Ext.apply(pickerCfg, {
                                itemId: item,
                                listeners: {
                                    select: me.onPickerSelect,
                                    scope: me
                                }
                            }),
                        ]
                    }),
                    listeners: {
                        scope: me,
                        checkchange: me.onCheckChange
                    }
                };
                item = me.fields[item] = Ext.create('Ext.menu.CheckItem', cfg);
            }
            //me.add(item);
            me.menu.add(item);
        }
        me.values = {};
    },

    onCheckChange : function (item, checked) {
        var me = this,
            picker = item.menu.items.first(),
            itemId = picker.itemId,
            values = me.values;

        if (checked) {
            values[itemId] = picker.getValue();
        } else {
            delete values[itemId]
        }
        me.setActive(me.isActivatable());
        me.fireEvent('update', me);
    },

    /**
     * @private
     * Handler method called when there is a keyup event on an input
     * item of this menu.
     */
    onInputKeyUp : function (field, e) {
        var k = e.getKey();
        if (k == e.RETURN && field.isValid()) {
            e.stopEvent();
            this.menu.hide();
        }
    },

    /**
     * Handler for when the DatePicker for a field fires the 'select' event
     * @param {Ext.picker.Date} picker
     * @param {Object} date
     */
    onMenuSelect : function (picker, date) {
        var fields = this.fields,
            field = this.fields[picker.itemId];

        field.setChecked(true);

        if (field == fields.on) {
            fields.before.setChecked(false, true);
            fields.after.setChecked(false, true);
        } else {
            fields.on.setChecked(false, true);
            if (field == fields.after && this.getFieldValue('before') < date) {
                fields.before.setChecked(false, true);
            } else if (field == fields.before && this.getFieldValue('after') > date) {
                fields.after.setChecked(false, true);
            }
        }
        this.fireEvent('update', this);

        picker.up('menu').hide();
    },

    /**
     * @private
     * Template method that is to get and return the value of the filter.
     * @return {String} The value of this filter
     */
    getValue : function () {
        var key, result = {};
        for (key in this.fields) {
            if (this.fields[key].checked) {
                result[key] = this.getFieldValue(key);
            }
        }
        return result;
    },

    /**
     * @private
     * Template method that is to set the value of the filter.
     * @param {Object} value The value to set the filter
     * @param {Boolean} preserve true to preserve the checked status
     * of the other fields.  Defaults to false, unchecking the
     * other fields
     */
    setValue : function (value, preserve) {
        var key;
        for (key in this.fields) {
            if(value[key]){
                this.getPicker(key).setValue(value[key]);
                this.fields[key].setChecked(true);
            } else if (!preserve) {
                this.fields[key].setChecked(false);
            }
        }
        this.fireEvent('update', this);
    },

    /**
     * @private
     * Template method that is to return <tt>true</tt> if the filter
     * has enough configuration information to be activated.
     * @return {Boolean}
     */
    isActivatable : function () {
        var key;
        for (key in this.fields) {
            if (this.fields[key].checked) {
                return true;
            }
        }
        return false;
    },

    /**
     * @private
     * Template method that is to get and return serialized filter data for
     * transmission to the server.
     * @return {Object/Array} An object or collection of objects containing
     * key value pairs representing the current configuration of the filter.
     */
    getSerialArgs : function () {
        var args = [];
        for (var key in this.fields) {
            if(this.fields[key].checked){
                args.push({
                    type: 'date',
                    comparison: this.compareMap[key],
                    value: Ext.Date.format(this.getFieldValue(key), this.dateFormat)
                });
            }
        }
        return args;
    },

    /**
     * Get and return the date menu picker value
     * @param {String} item The field identifier ('before', 'after', 'on')
     * @return {Date} Gets the current selected value of the date field
     */
    getFieldValue : function(item){
        return this.values[item];
    },

    /**
     * Gets the menu picker associated with the passed field
     * @param {String} item The field identifier ('before', 'after', 'on')
     * @return {Object} The menu picker
     */
    getPicker : function(item){
        return this.fields[item].menu.items.first();
    },

    /**
     * Template method that is to validate the provided Ext.data.Record
     * against the filters configuration.
     * @param {Ext.data.Record} record The record to validate
     * @return {Boolean} true if the record is valid within the bounds
     * of the filter, false otherwise.
     */
    validateRecord : function (record) {
        var key,
            pickerValue,
            val = record.get(this.dataIndex),
            clearTime = Ext.Date.clearTime;

        if(!Ext.isDate(val)){
            return false;
        }
        val = clearTime(val, true).getTime();

        for (key in this.fields) {
            if (this.fields[key].checked) {
                pickerValue = clearTime(this.getFieldValue(key), true).getTime();
                if (key == 'before' && pickerValue <= val) {
                    return false;
                }
                if (key == 'after' && pickerValue >= val) {
                    return false;
                }
                if (key == 'on' && pickerValue != val) {
                    return false;
                }
            }
        }
        return true;
    },

    onPickerSelect: function(picker, date) {
        // keep track of the picker value separately because the menu gets destroyed
        // when columns order changes.  We return this value from getValue() instead
        // of picker.getValue()
        this.values[picker.itemId] = date;
        this.fireEvent('update', this);
    }
});

/**
 * @class Ext.ux.grid.filter.ListFilter
 * @extends Ext.ux.grid.filter.Filter
 * <p>List filters are able to be preloaded/backed by an Ext.data.Store to load
 * their options the first time they are shown. ListFilter utilizes the
 * {@link Ext.ux.grid.menu.ListMenu} component.</p>
 * <p>Although not shown here, this class accepts all configuration options
 * for {@link Ext.ux.grid.menu.ListMenu}.</p>
 *
 * <p><b><u>Example Usage:</u></b></p>
 * <pre><code>
var filters = Ext.create('Ext.ux.grid.GridFilters', {
    ...
    filters: [{
        type: 'list',
        dataIndex: 'size',
        phpMode: true,
        // options will be used as data to implicitly creates an ArrayStore
        options: ['extra small', 'small', 'medium', 'large', 'extra large']
    }]
});
 * </code></pre>
 *
 */
Ext.define('Ext.ux.grid.filter.ListFilter', {
    extend: 'Ext.ux.grid.filter.Filter',
    alias: 'gridfilter.list',

    /**
     * @cfg {Array} options
     * <p><code>data</code> to be used to implicitly create a data store
     * to back this list when the data source is <b>local</b>. If the
     * data for the list is remote, use the <code>{@link #store}</code>
     * config instead.</p>
     * <br><p>Each item within the provided array may be in one of the
     * following formats:</p>
     * <div class="mdetail-params"><ul>
     * <li><b>Array</b> :
     * <pre><code>
options: [
    [11, 'extra small'],
    [18, 'small'],
    [22, 'medium'],
    [35, 'large'],
    [44, 'extra large']
]
     * </code></pre>
     * </li>
     * <li><b>Object</b> :
     * <pre><code>
labelField: 'name', // override default of 'text'
options: [
    {id: 11, name:'extra small'},
    {id: 18, name:'small'},
    {id: 22, name:'medium'},
    {id: 35, name:'large'},
    {id: 44, name:'extra large'}
]
     * </code></pre>
     * </li>
     * <li><b>String</b> :
     * <pre><code>
     * options: ['extra small', 'small', 'medium', 'large', 'extra large']
     * </code></pre>
     * </li>
     */
    /**
     * @cfg {Boolean} phpMode
     * <p>Adjust the format of this filter. Defaults to false.</p>
     * <br><p>When GridFilters <code>@cfg encode = false</code> (default):</p>
     * <pre><code>
// phpMode == false (default):
filter[0][data][type] list
filter[0][data][value] value1
filter[0][data][value] value2
filter[0][field] prod

// phpMode == true:
filter[0][data][type] list
filter[0][data][value] value1, value2
filter[0][field] prod
     * </code></pre>
     * When GridFilters <code>@cfg encode = true</code>:
     * <pre><code>
// phpMode == false (default):
filter : [{"type":"list","value":["small","medium"],"field":"size"}]

// phpMode == true:
filter : [{"type":"list","value":"small,medium","field":"size"}]
     * </code></pre>
     */
    phpMode : false,
    /**
     * @cfg {Ext.data.Store} store
     * The {@link Ext.data.Store} this list should use as its data source
     * when the data source is <b>remote</b>. If the data for the list
     * is local, use the <code>{@link #options}</code> config instead.
     */

    /**
     * @private
     * Template method that is to initialize the filter.
     * @param {Object} config
     */
    init : function (config) {
        this.dt = Ext.create('Ext.util.DelayedTask', this.fireUpdate, this);
    },

    /**
     * @private @override
     * Creates the Menu for this filter.
     * @param {Object} config Filter configuration
     * @return {Ext.menu.Menu}
     */
    createMenu: function(config) {
        var menu = Ext.create('Ext.ux.grid.menu.ListMenu', config);
        menu.on('checkchange', this.onCheckChange, this);
        return menu;
    },

    /**
     * @private
     * Template method that is to get and return the value of the filter.
     * @return {String} The value of this filter
     */
    getValue : function () {
        return this.menu.getSelected();
    },
    /**
     * @private
     * Template method that is to set the value of the filter.
     * @param {Object} value The value to set the filter
     */
    setValue : function (value) {
        this.menu.setSelected(value);
        this.fireEvent('update', this);
    },

    /**
     * @private
     * Template method that is to return <tt>true</tt> if the filter
     * has enough configuration information to be activated.
     * @return {Boolean}
     */
    isActivatable : function () {
        return this.getValue().length > 0;
    },

    /**
     * @private
     * Template method that is to get and return serialized filter data for
     * transmission to the server.
     * @return {Object/Array} An object or collection of objects containing
     * key value pairs representing the current configuration of the filter.
     */
    getSerialArgs : function () {
        return {type: 'list', value: this.phpMode ? this.getValue().join(',') : this.getValue()};
    },

    /** @private */
    onCheckChange : function(){
        this.dt.delay(this.updateBuffer);
    },


    /**
     * Template method that is to validate the provided Ext.data.Record
     * against the filters configuration.
     * @param {Ext.data.Record} record The record to validate
     * @return {Boolean} true if the record is valid within the bounds
     * of the filter, false otherwise.
     */
    validateRecord : function (record) {
        var valuesArray = this.getValue();
        return Ext.Array.indexOf(valuesArray, record.get(this.dataIndex)) > -1;
    }
});

/**
 * @class Ext.ux.grid.filter.NumericFilter
 * @extends Ext.ux.grid.filter.Filter
 * Filters using an Ext.ux.grid.menu.RangeMenu.
 * <p><b><u>Example Usage:</u></b></p>
 * <pre><code>
var filters = Ext.create('Ext.ux.grid.GridFilters', {
    ...
    filters: [{
        type: 'numeric',
        dataIndex: 'price'
    }]
});
 * </code></pre>
 * <p>Any of the configuration options for {@link Ext.ux.grid.menu.RangeMenu} can also be specified as
 * configurations to NumericFilter, and will be copied over to the internal menu instance automatically.</p>
 */
Ext.define('Ext.ux.grid.filter.NumericFilter', {
    extend: 'Ext.ux.grid.filter.Filter',
    alias: 'gridfilter.numeric',
    uses: ['Ext.form.field.Number'],

    /**
     * @private @override
     * Creates the Menu for this filter.
     * @param {Object} config Filter configuration
     * @return {Ext.menu.Menu}
     */
    createMenu: function(config) {
        var me = this,
            menu;
        menu = Ext.create('Ext.ux.grid.menu.RangeMenu', config);
        menu.on('update', me.fireUpdate, me);
        return menu;
    },

    /**
     * @private
     * Template method that is to get and return the value of the filter.
     * @return {String} The value of this filter
     */
    getValue : function () {
        return this.menu.getValue();
    },

    /**
     * @private
     * Template method that is to set the value of the filter.
     * @param {Object} value The value to set the filter
     */
    setValue : function (value) {
        this.menu.setValue(value);
    },

    /**
     * @private
     * Template method that is to return <tt>true</tt> if the filter
     * has enough configuration information to be activated.
     * @return {Boolean}
     */
    isActivatable : function () {
        var values = this.getValue(),
            key;
        for (key in values) {
            if (values[key] !== undefined) {
                return true;
            }
        }
        return false;
    },

    /**
     * @private
     * Template method that is to get and return serialized filter data for
     * transmission to the server.
     * @return {Object/Array} An object or collection of objects containing
     * key value pairs representing the current configuration of the filter.
     */
    getSerialArgs : function () {
        var key,
            args = [],
            values = this.menu.getValue();
        for (key in values) {
            args.push({
                type: 'numeric',
                comparison: key,
                value: values[key]
            });
        }
        return args;
    },

    /**
     * Template method that is to validate the provided Ext.data.Record
     * against the filters configuration.
     * @param {Ext.data.Record} record The record to validate
     * @return {Boolean} true if the record is valid within the bounds
     * of the filter, false otherwise.
     */
    validateRecord : function (record) {
        var val = record.get(this.dataIndex),
            values = this.getValue(),
            isNumber = Ext.isNumber;
        if (isNumber(values.eq) && val != values.eq) {
            return false;
        }
        if (isNumber(values.lt) && val >= values.lt) {
            return false;
        }
        if (isNumber(values.gt) && val <= values.gt) {
            return false;
        }
        return true;
    }
});

/**
 * @class Ext.ux.grid.filter.StringFilter
 * @extends Ext.ux.grid.filter.Filter
 * Filter by a configurable Ext.form.field.Text
 * <p><b><u>Example Usage:</u></b></p>
 * <pre><code>
var filters = Ext.create('Ext.ux.grid.GridFilters', {
    ...
    filters: [{
        // required configs
        type: 'string',
        dataIndex: 'name',

        // optional configs
        value: 'foo',
        active: true, // default is false
        iconCls: 'ux-gridfilter-text-icon' // default
        // any Ext.form.field.Text configs accepted
    }]
});
 * </code></pre>
 */
Ext.define('Ext.ux.grid.filter.StringFilter', {
    extend: 'Ext.ux.grid.filter.Filter',
    alias: 'gridfilter.string',

    /**
     * @cfg {String} iconCls
     * The iconCls to be applied to the menu item.
     * Defaults to <tt>'ux-gridfilter-text-icon'</tt>.
     */
    iconCls : 'ux-gridfilter-text-icon',

    emptyText: 'Enter Filter Text...',
    selectOnFocus: true,
    width: 125,

    /**
     * @private
     * Template method that is to initialize the filter and install required menu items.
     */
    init : function (config) {
        Ext.applyIf(config, {
            enableKeyEvents: true,
            iconCls: this.iconCls,
            hideLabel: true,
            listeners: {
                scope: this,
                keyup: this.onInputKeyUp,
                el: {
                    click: function(e) {
                        e.stopPropagation();
                    }
                }
            }
        });

        this.inputItem = Ext.create('Ext.form.field.Text', config);
        this.menu.add(this.inputItem);
        this.updateTask = Ext.create('Ext.util.DelayedTask', this.fireUpdate, this);
    },

    /**
     * @private
     * Template method that is to get and return the value of the filter.
     * @return {String} The value of this filter
     */
    getValue : function () {
        return this.inputItem.getValue();
    },

    /**
     * @private
     * Template method that is to set the value of the filter.
     * @param {Object} value The value to set the filter
     */
    setValue : function (value) {
        this.inputItem.setValue(value);
        this.fireEvent('update', this);
    },

    /**
     * @private
     * Template method that is to return <tt>true</tt> if the filter
     * has enough configuration information to be activated.
     * @return {Boolean}
     */
    isActivatable : function () {
        return this.inputItem.getValue().length > 0;
    },

    /**
     * @private
     * Template method that is to get and return serialized filter data for
     * transmission to the server.
     * @return {Object/Array} An object or collection of objects containing
     * key value pairs representing the current configuration of the filter.
     */
    getSerialArgs : function () {
        return {type: 'string', value: this.getValue()};
    },

    /**
     * Template method that is to validate the provided Ext.data.Record
     * against the filters configuration.
     * @param {Ext.data.Record} record The record to validate
     * @return {Boolean} true if the record is valid within the bounds
     * of the filter, false otherwise.
     */
    validateRecord : function (record) {
        var val = record.get(this.dataIndex);

        if(typeof val != 'string') {
            return (this.getValue().length === 0);
        }

        return val.toLowerCase().indexOf(this.getValue().toLowerCase()) > -1;
    },

    /**
     * @private
     * Handler method called when there is a keyup event on this.inputItem
     */
    onInputKeyUp : function (field, e) {
        var k = e.getKey();
        if (k == e.RETURN && field.isValid()) {
            e.stopEvent();
            this.menu.hide();
            return;
        }
        // restart the timer
        this.updateTask.delay(this.updateBuffer);
    }
});

/**
 * FiltersFeature is a grid {@link Ext.grid.feature.Feature feature} that allows for a slightly more
 * robust representation of filtering than what is provided by the default store.
 *
 * Filtering is adjusted by the user using the grid's column header menu (this menu can be
 * disabled through configuration). Through this menu users can configure, enable, and
 * disable filters for each column.
 *
 * #Features#
 *
 * ##Filtering implementations:##
 *
 * Default filtering for Strings, Numeric Ranges, Date Ranges, Lists (which can be backed by a
 * {@link Ext.data.Store}), and Boolean. Additional custom filter types and menus are easily
 * created by extending {@link Ext.ux.grid.filter.Filter}.
 *
 * ##Graphical Indicators:##
 *
 * Columns that are filtered have {@link #filterCls a configurable css class} applied to the column headers.
 *
 * ##Automatic Reconfiguration:##
 *
 * Filters automatically reconfigure when the grid 'reconfigure' event fires.
 *
 * ##Stateful:##
 *
 * Filter information will be persisted across page loads by specifying a `stateId`
 * in the Grid configuration.
 *
 * The filter collection binds to the {@link Ext.grid.Panel#beforestaterestore beforestaterestore}
 * and {@link Ext.grid.Panel#beforestatesave beforestatesave} events in order to be stateful.
 *
 * ##GridPanel Changes:##
 *
 * - A `filters` property is added to the GridPanel using this feature.
 * - A `filterupdate` event is added to the GridPanel and is fired upon onStateChange completion.
 *
 * ##Server side code examples:##
 *
 * - [PHP](http://www.vinylfox.com/extjs/grid-filter-php-backend-code.php) - (Thanks VinylFox)
 * - [Ruby on Rails](http://extjs.com/forum/showthread.php?p=77326#post77326) - (Thanks Zyclops)
 * - [Ruby on Rails](http://extjs.com/forum/showthread.php?p=176596#post176596) - (Thanks Rotomaul)
 *
 * #Example usage:#
 *
 *     var store = Ext.create('Ext.data.Store', {
 *         pageSize: 15
 *         ...
 *     });
 *
 *     var filtersCfg = {
 *         ftype: 'filters',
 *         autoReload: false, //don't reload automatically
 *         local: true, //only filter locally
 *         // filters may be configured through the plugin,
 *         // or in the column definition within the headers configuration
 *         filters: [{
 *             type: 'numeric',
 *             dataIndex: 'id'
 *         }, {
 *             type: 'string',
 *             dataIndex: 'name'
 *         }, {
 *             type: 'numeric',
 *             dataIndex: 'price'
 *         }, {
 *             type: 'date',
 *             dataIndex: 'dateAdded'
 *         }, {
 *             type: 'list',
 *             dataIndex: 'size',
 *             options: ['extra small', 'small', 'medium', 'large', 'extra large'],
 *             phpMode: true
 *         }, {
 *             type: 'boolean',
 *             dataIndex: 'visible'
 *         }]
 *     };
 *
 *     var grid = Ext.create('Ext.grid.Panel', {
 *          store: store,
 *          columns: ...,
 *          features: [filtersCfg],
 *          height: 400,
 *          width: 700,
 *          bbar: Ext.create('Ext.PagingToolbar', {
 *              store: store
 *          })
 *     });
 *
 *     // a filters property is added to the GridPanel
 *     grid.filters
 */
Ext.define('Ext.ux.grid.FiltersFeature', {
    extend: 'Ext.grid.feature.Feature',
    alias: 'feature.filters',
    uses: [
        'Ext.ux.grid.menu.ListMenu',
        'Ext.ux.grid.menu.RangeMenu',
        'Ext.ux.grid.filter.BooleanFilter',
        'Ext.ux.grid.filter.DateFilter',
        'Ext.ux.grid.filter.ListFilter',
        'Ext.ux.grid.filter.NumericFilter',
        'Ext.ux.grid.filter.StringFilter'
    ],

    /**
     * @cfg {Boolean} autoReload
     * Defaults to true, reloading the datasource when a filter change happens.
     * Set this to false to prevent the datastore from being reloaded if there
     * are changes to the filters.  See <code>{@link #updateBuffer}</code>.
     */
    autoReload : true,
    /**
     * @cfg {Boolean} encode
     * Specify true for {@link #buildQuery} to use Ext.util.JSON.encode to
     * encode the filter query parameter sent with a remote request.
     * Defaults to false.
     */
    /**
     * @cfg {Array} filters
     * An Array of filters config objects. Refer to each filter type class for
     * configuration details specific to each filter type. Filters for Strings,
     * Numeric Ranges, Date Ranges, Lists, and Boolean are the standard filters
     * available.
     */
    /**
     * @cfg {String} filterCls
     * The css class to be applied to column headers with active filters.
     * Defaults to <tt>'ux-filterd-column'</tt>.
     */
    filterCls : 'ux-filtered-column',
    /**
     * @cfg {Boolean} local
     * <tt>true</tt> to use Ext.data.Store filter functions (local filtering)
     * instead of the default (<tt>false</tt>) server side filtering.
     */
    local : false,
    /**
     * @cfg {String} menuFilterText
     * defaults to <tt>'Filters'</tt>.
     */
    menuFilterText : 'Filters',
    /**
     * @cfg {String} paramPrefix
     * The url parameter prefix for the filters.
     * Defaults to <tt>'filter'</tt>.
     */
    paramPrefix : 'filter',
    /**
     * @cfg {Boolean} showMenu
     * Defaults to true, including a filter submenu in the default header menu.
     */
    showMenu : true,
    /**
     * @cfg {String} stateId
     * Name of the value to be used to store state information.
     */
    stateId : undefined,
    /**
     * @cfg {Number} updateBuffer
     * Number of milliseconds to defer store updates since the last filter change.
     */
    updateBuffer : 500,

    // doesn't handle grid body events
    hasFeatureEvent: false,


    /** @private */
    constructor : function (config) {
        var me = this;

        config = config || {};
        Ext.apply(me, config);

        me.deferredUpdate = Ext.create('Ext.util.DelayedTask', me.reload, me);

        // Init filters
        me.filters = me.createFiltersCollection();
        me.filterConfigs = config.filters;
    },

    attachEvents: function() {
        var me = this,
            view = me.view,
            headerCt = view.headerCt,
            grid = me.getGridPanel();

        me.bindStore(view.getStore(), true);

        // Listen for header menu being created
        headerCt.on('menucreate', me.onMenuCreate, me);

        view.on('refresh', me.onRefresh, me);
        grid.on({
            scope: me,
            beforestaterestore: me.applyState,
            beforestatesave: me.saveState,
            beforedestroy: me.destroy
        });

        // Add event and filters shortcut on grid panel
        grid.filters = me;
        grid.addEvents('filterupdate');
    },

    createFiltersCollection: function () {
        return Ext.create('Ext.util.MixedCollection', false, function (o) {
            return o ? o.dataIndex : null;
        });
    },

    /**
     * @private Create the Filter objects for the current configuration, destroying any existing ones first.
     */
    createFilters: function() {
        var me = this,
            hadFilters = me.filters.getCount(),
            grid = me.getGridPanel(),
            filters = me.createFiltersCollection(),
            model = grid.store.model,
            fields = model.prototype.fields,
            field,
            filter,
            state;

        if (hadFilters) {
            state = {};
            me.saveState(null, state);
        }

        function add (dataIndex, config, filterable) {
            if (dataIndex && (filterable || config)) {
                field = fields.get(dataIndex);
                filter = {
                    dataIndex: dataIndex,
                    type: (field && field.type && field.type.type) || 'auto'
                };

                if (Ext.isObject(config)) {
                    Ext.apply(filter, config);
                }

                filters.replace(filter);
            }
        }

        // We start with filters from our config
        Ext.Array.each(me.filterConfigs, function (filterConfig) {
            add(filterConfig.dataIndex, filterConfig);
        });

        // Then we merge on filters from the columns in the grid. The columns' filters take precedence.
        Ext.Array.each(grid.columns, function (column) {
            if (column.filterable === false) {
                filters.removeAtKey(column.dataIndex);
            } else {
                add(column.dataIndex, column.filter, column.filterable);
            }
        });
        

        me.removeAll();
        if (filters.items) {
            me.initializeFilters(filters.items);
        }

        if (hadFilters) {
            me.applyState(null, state);
        }
    },

    /**
     * @private
     */
    initializeFilters: function(filters) {
        var me = this,
            filtersLength = filters.length,
            i, filter, FilterClass;

        for (i = 0; i < filtersLength; i++) {
            filter = filters[i];
            if (filter) {
                FilterClass = me.getFilterClass(filter.type);
                filter = filter.menu ? filter : new FilterClass(filter);
                me.filters.add(filter);
                Ext.util.Observable.capture(filter, this.onStateChange, this);
            }
        }
    },

    /**
     * @private Handle creation of the grid's header menu. Initializes the filters and listens
     * for the menu being shown.
     */
    onMenuCreate: function(headerCt, menu) {
        var me = this;
        me.createFilters();
        menu.on('beforeshow', me.onMenuBeforeShow, me);
    },

    /**
     * @private Handle showing of the grid's header menu. Sets up the filter item and menu
     * appropriate for the target column.
     */
    onMenuBeforeShow: function(menu) {
        var me = this,
            menuItem, filter;

        if (me.showMenu) {
            menuItem = me.menuItem;
            if (!menuItem || menuItem.isDestroyed) {
                me.createMenuItem(menu);
                menuItem = me.menuItem;
            }

            filter = me.getMenuFilter();

            if (filter) {
                menuItem.setMenu(filter.menu, false);
                menuItem.setChecked(filter.active);
                // disable the menu if filter.disabled explicitly set to true
                menuItem.setDisabled(filter.disabled === true);
            }
            menuItem.setVisible(!!filter);
            this.sep.setVisible(!!filter);
        }
    },


    createMenuItem: function(menu) {
        var me = this;
        me.sep  = menu.add('-');
        me.menuItem = menu.add({
            checked: false,
            itemId: 'filters',
            text: me.menuFilterText,
            listeners: {
                scope: me,
                checkchange: me.onCheckChange,
                beforecheckchange: me.onBeforeCheck
            }
        });
    },

    getGridPanel: function() {
        return this.view.up('gridpanel');
    },

    /**
     * @private
     * Handler for the grid's beforestaterestore event (fires before the state of the
     * grid is restored).
     * @param {Object} grid The grid object
     * @param {Object} state The hash of state values returned from the StateProvider.
     */
    applyState : function (grid, state) {
        var me = this,
            key, filter;
        me.applyingState = true;
        me.clearFilters();
        if (state.filters) {
            for (key in state.filters) {
                if (state.filters.hasOwnProperty(key)) {
                    filter = me.filters.get(key);
                    if (filter) {
                        filter.setValue(state.filters[key]);
                        filter.setActive(true);
                    }
                }
            }
        }
        me.deferredUpdate.cancel();
        if (me.local) {
            me.reload();
        }
        delete me.applyingState;
        delete state.filters;
    },

    /**
     * Saves the state of all active filters
     * @param {Object} grid
     * @param {Object} state
     * @return {Boolean}
     */
    saveState : function (grid, state) {
        var filters = {};
        this.filters.each(function (filter) {
            if (filter.active) {
                filters[filter.dataIndex] = filter.getValue();
            }
        });
        return (state.filters = filters);
    },

    /**
     * @private
     * Handler called by the grid 'beforedestroy' event
     */
    destroy : function () {
        var me = this;
        Ext.destroyMembers(me, 'menuItem', 'sep');
        me.removeAll();
        me.clearListeners();
    },

    /**
     * Remove all filters, permanently destroying them.
     */
    removeAll : function () {
        if(this.filters){
            Ext.destroy.apply(Ext, this.filters.items);
            // remove all items from the collection
            this.filters.clear();
        }
    },


    /**
     * Changes the data store bound to this view and refreshes it.
     * @param {Ext.data.Store} store The store to bind to this view
     */
    bindStore : function(store) {
        var me = this;

        // Unbind from the old Store
        if (me.store && me.storeListeners) {
            me.store.un(me.storeListeners);
        }

        // Set up correct listeners
        if (store) {
            me.storeListeners = {
                scope: me
            };
            if (me.local) {
                me.storeListeners.load = me.onLoad;
            } else {
                me.storeListeners['before' + (store.buffered ? 'prefetch' : 'load')] = me.onBeforeLoad;
            }
            store.on(me.storeListeners);
        } else {
            delete me.storeListeners;
        }
        me.store = store;
    },

    /**
     * @private
     * Get the filter menu from the filters MixedCollection based on the clicked header
     */
    getMenuFilter : function () {
        var header = this.view.headerCt.getMenu().activeHeader;
        return header ? this.filters.get(header.dataIndex) : null;
    },

    /** @private */
    onCheckChange : function (item, value) {
        this.getMenuFilter().setActive(value);
    },

    /** @private */
    onBeforeCheck : function (check, value) {
        return !value || this.getMenuFilter().isActivatable();
    },

    /**
     * @private
     * Handler for all events on filters.
     * @param {String} event Event name
     * @param {Object} filter Standard signature of the event before the event is fired
     */
    onStateChange : function (event, filter) {
        if (event !== 'serialize') {
            var me = this,
                grid = me.getGridPanel();

            if (filter == me.getMenuFilter()) {
                me.menuItem.setChecked(filter.active, false);
            }

            if ((me.autoReload || me.local) && !me.applyingState) {
                me.deferredUpdate.delay(me.updateBuffer);
            }
            me.updateColumnHeadings();

            if (!me.applyingState) {
                grid.saveState();
            }
            grid.fireEvent('filterupdate', me, filter);
        }
    },

    /**
     * @private
     * Handler for store's beforeload event when configured for remote filtering
     * @param {Object} store
     * @param {Object} options
     */
    onBeforeLoad : function (store, options) {
        options.params = options.params || {};
        this.cleanParams(options.params);
        var params = this.buildQuery(this.getFilterData());
        Ext.apply(options.params, params);
    },

    /**
     * @private
     * Handler for store's load event when configured for local filtering
     * @param {Object} store
     */
    onLoad : function (store) {
        store.filterBy(this.getRecordFilter());
    },

    /**
     * @private
     * Handler called when the grid's view is refreshed
     */
    onRefresh : function () {
        this.updateColumnHeadings();
    },

    /**
     * Update the styles for the header row based on the active filters
     */
    updateColumnHeadings : function () {
        var me = this,
            headerCt = me.view.headerCt;
        if (headerCt) {
            headerCt.items.each(function(header) {
                var filter = me.getFilter(header.dataIndex);
                header[filter && filter.active ? 'addCls' : 'removeCls'](me.filterCls);
            });
        }
    },

    /** @private */
    reload : function () {
        var me = this,
            store = me.view.getStore();

        if (me.local) {
            store.clearFilter(true);
            store.filterBy(me.getRecordFilter());
            store.sort();
        } else {
            me.deferredUpdate.cancel();
            if (store.buffered) {
                store.pageMap.clear();
            }
            store.loadPage(1);
        }
    },

    /**
     * Method factory that generates a record validator for the filters active at the time
     * of invokation.
     * @private
     */
    getRecordFilter : function () {
        var f = [], len, i;
        this.filters.each(function (filter) {
            if (filter.active) {
                f.push(filter);
            }
        });

        len = f.length;
        return function (record) {
            for (i = 0; i < len; i++) {
                if (!f[i].validateRecord(record)) {
                    return false;
                }
            }
            return true;
        };
    },

    /**
     * Adds a filter to the collection and observes it for state change.
     * @param {Object/Ext.ux.grid.filter.Filter} config A filter configuration or a filter object.
     * @return {Ext.ux.grid.filter.Filter} The existing or newly created filter object.
     */
    addFilter : function (config) {
        var me = this,
            columns = me.getGridPanel().columns,
            i, columnsLength, column, filtersLength, filter;

        
        for (i = 0, columnsLength = columns.length; i < columnsLength; i++) {
            column = columns[i];
            if (column.dataIndex === config.dataIndex) {
                column.filter = config;
            }
        }
        
        if (me.view.headerCt.menu) {
            me.createFilters();
        } else {
            // Call getMenu() to ensure the menu is created, and so, also are the filters. We cannot call
            // createFilters() withouth having a menu because it will cause in a recursion to applyState()
            // that ends up to clear all the filter values. This is likely to happen when we reorder a column
            // and then add a new filter before the menu is recreated.
            me.view.headerCt.getMenu();
        }
        
        for (i = 0, filtersLength = me.filters.items.length; i < filtersLength; i++) {
            filter = me.filters.items[i];
            if (filter.dataIndex === config.dataIndex) {
                return filter;
            }
        }
    },

    /**
     * Adds filters to the collection.
     * @param {Array} filters An Array of filter configuration objects.
     */
    addFilters : function (filters) {
        if (filters) {
            var me = this,
                i, filtersLength;
            for (i = 0, filtersLength = filters.length; i < filtersLength; i++) {
                me.addFilter(filters[i]);
            }
        }
    },

    /**
     * Returns a filter for the given dataIndex, if one exists.
     * @param {String} dataIndex The dataIndex of the desired filter object.
     * @return {Ext.ux.grid.filter.Filter}
     */
    getFilter : function (dataIndex) {
        return this.filters.get(dataIndex);
    },

    /**
     * Turns all filters off. This does not clear the configuration information
     * (see {@link #removeAll}).
     */
    clearFilters : function () {
        this.filters.each(function (filter) {
            filter.setActive(false);
        });
    },

    /**
     * Returns an Array of the currently active filters.
     * @return {Array} filters Array of the currently active filters.
     */
    getFilterData : function () {
        var filters = [], i, len;

        this.filters.each(function (f) {
            if (f.active) {
                var d = [].concat(f.serialize());
                for (i = 0, len = d.length; i < len; i++) {
                    filters.push({
                        field: f.dataIndex,
                        data: d[i]
                    });
                }
            }
        });
        return filters;
    },

    /**
     * Function to take the active filters data and build it into a query.
     * The format of the query depends on the {@link #encode} configuration:
     *
     *   - `false` (Default) :
     *     Flatten into query string of the form (assuming <code>{@link #paramPrefix}='filters'</code>:
     *
     *         filters[0][field]="someDataIndex"&
     *         filters[0][data][comparison]="someValue1"&
     *         filters[0][data][type]="someValue2"&
     *         filters[0][data][value]="someValue3"&
     *
     *
     *   - `true` :
     *     JSON encode the filter data
     *
     *         {filters:[{"field":"someDataIndex","comparison":"someValue1","type":"someValue2","value":"someValue3"}]}
     *
     * Override this method to customize the format of the filter query for remote requests.
     *
     * @param {Array} filters A collection of objects representing active filters and their configuration.
     * Each element will take the form of {field: dataIndex, data: filterConf}. dataIndex is not assured
     * to be unique as any one filter may be a composite of more basic filters for the same dataIndex.
     *
     * @return {Object} Query keys and values
     */
    buildQuery : function (filters) {
        var p = {}, i, f, root, dataPrefix, key, tmp,
            len = filters.length;

        if (!this.encode){
            for (i = 0; i < len; i++) {
                f = filters[i];
                root = [this.paramPrefix, '[', i, ']'].join('');
                p[root + '[field]'] = f.field;

                dataPrefix = root + '[data]';
                for (key in f.data) {
                    p[[dataPrefix, '[', key, ']'].join('')] = f.data[key];
                }
            }
        } else {
            tmp = [];
            for (i = 0; i < len; i++) {
                f = filters[i];
                tmp.push(Ext.apply(
                    {},
                    {field: f.field},
                    f.data
                ));
            }
            // only build if there is active filter
            if (tmp.length > 0){
                p[this.paramPrefix] = Ext.JSON.encode(tmp);
            }
        }
        return p;
    },

    /**
     * Removes filter related query parameters from the provided object.
     * @param {Object} p Query parameters that may contain filter related fields.
     */
    cleanParams : function (p) {
        // if encoding just delete the property
        if (this.encode) {
            delete p[this.paramPrefix];
        // otherwise scrub the object of filter data
        } else {
            var regex, key;
            regex = new RegExp('^' + this.paramPrefix + '\[[0-9]+\]');
            for (key in p) {
                if (regex.test(key)) {
                    delete p[key];
                }
            }
        }
    },

    /**
     * Function for locating filter classes, overwrite this with your favorite
     * loader to provide dynamic filter loading.
     * @param {String} type The type of filter to load ('Filter' is automatically
     * appended to the passed type; eg, 'string' becomes 'StringFilter').
     * @return {Function} The Ext.ux.grid.filter.Class
     */
    getFilterClass : function (type) {
        // map the supported Ext.data.Field type values into a supported filter
        switch(type) {
            case 'auto':
              type = 'string';
              break;
            case 'int':
            case 'float':
              type = 'numeric';
              break;
            case 'bool':
              type = 'boolean';
              break;
        }
        return Ext.ClassManager.getByAlias('gridfilter.' + type);
    }
});

Ext.define('Imits.widget.grid.RansackFiltersFeature', {
    extend: 'Ext.ux.grid.FiltersFeature',
    alias: 'feature.ransack_filters',

    /**
     * @cfg {Boolean} encode
     * Unlike the base class, this parameter is totally ignored when
     * building a query
     */
    encode: false,

    buildQuerySingle: function (filter) {
        var param = {};
        switch (filter.data.type) {
            case 'numeric':
                if(filter.data.comparison != 'eq') {
                    param['q[' + filter.field + '_'+filter.data.comparison+']'] = filter.data.value;
                } else {
                    param['q[' + filter.field + '_in][]'] = filter.data.value;
                }
                break;
            case 'string':
                if(filter.field == 'id') {
                    param['q[' + filter.field + '_in][]'] = filter.data.value.split(',');
                }else {
                    param['q[' + filter.field + '_ci_in][]'] = filter.data.value;
                }
                break;
            case 'list':
                if (filter.field == 'no_consortium_id') {
                  if (filter.data.value == '1'){
                    param['q[' + 'consortium_id_null]' ] = 1;
                  }
                  else {
                    param['q[' + 'consortium_id_not_null]' ] = 1;
                  }
                }
                else {
                  param['q[' + filter.field + '_ci_in][]'] = filter.data.value;
                }
                break;

            case 'boolean':
                param['q[' + filter.field + '_eq]'] = filter.data.value;
                break;

            case 'date':
                var dateParts = filter.data.value.split('/');
                param['q[' + filter.field + '_' + filter.data.comparison + ']'] = [dateParts[2]+'-'+dateParts[0]+'-'+dateParts[1]];
                break;
        }
        return param;
    },

    buildQuery: function (filters) {
        var params = {};

        var self = this;

        Ext.each(filters, function (filter) {
            var p = self.buildQuerySingle(filter);
            for (var i in p) {
                params[i] = p[i];
            }
        });

        return params;
    },

    cleanParams: function (params) {
        var regex, key;
        regex = new RegExp('^q\\[\\w+_ci_in\\]$');
        for (key in params) {
            if (regex.test(key)) {
                delete params[key];
            }
        }
    }
});

Ext.define('Imits.widget.CentresGrid', {
    extend: 'Imits.widget.Grid',

    requires: [
      'Imits.model.Centre',
      'Imits.widget.grid.RansackFiltersFeature',
      'Imits.Util'
    ],

    title: 'Centres',
    iconCls: 'icon-grid',
    columnLines: true,

    store: {
        model: 'Imits.model.Centre',
        autoLoad: true,
        autoSync: true,
        remoteSort: true,
        remoteFilter: true,
        pageSize: 25
    },

    selType: 'rowmodel',

    features: [
    {
        ftype: 'ransack_filters',
        local: false
    }
    ],

    plugins: [
      Ext.create('Ext.grid.plugin.RowEditing', {
          autoCancel: false,
          clicksToEdit: 1
      })
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
      dataIndex: 'name',
      header: 'ID',
      width:300,
      filter: {
        type: 'string'
      },
      editor: 'textfield'
    },
    {
      dataIndex: 'contact_name',
      header: 'Contact Name',
      width:300,
      filter: {
        type: 'string'
      },
      editor: 'textfield'
    },
    {
      dataIndex: 'contact_email',
      header: 'Contact Email',
      width:300,
      filter: {
        type: 'string'
      },
      editor: 'textfield'
    },
    {
      xtype:'actioncolumn',
      width:21,
      items: [{
        icon: '../images/icons/delete.png',
        tooltip: 'Delete',
        handler: function(grid, rowIndex, colIndex) {
          var record = grid.getStore().getAt(rowIndex);

          if(confirm("Remove centre?"))
            grid.getStore().removeAt(rowIndex)

        }
      }]
    }
    ]
});

Ext.define('Imits.widget.ContactsGrid', {
    extend: 'Imits.widget.Grid',

    requires: [
      'Imits.model.Contact',
      'Imits.widget.grid.RansackFiltersFeature',
      'Imits.Util'
    ],

    title: 'Contacts',
    iconCls: 'icon-grid',
    columnLines: true,

    store: {
        model: 'Imits.model.Contact',
        autoLoad: true,
        autoSync: true,
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

    plugins: [
      Ext.create('Ext.grid.plugin.RowEditing', {
          autoCancel: false,
          clicksToEdit: 1
      })
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
      dataIndex: "email",
      header: "Email address",
      width:300,
      filter: {
        type: 'string'
      },
      editor: 'textfield'
    },
    {
      xtype:'actioncolumn',
      width:21,
      items: [{
        icon: '../images/icons/delete.png',
        tooltip: 'Delete',
        handler: function(grid, rowIndex, colIndex) {
          var record = grid.getStore().getAt(rowIndex);

          if(confirm("Remove contact?"))
            grid.getStore().removeAt(rowIndex)

        }
      }]
    }
    ]
});

Ext.define('Imits.widget.SimpleCombo', {
    extend: 'Ext.form.field.ComboBox',
    alias: 'widget.simplecombo',
    typeAhead: false,
    triggerAction: 'all',
    forceSelection: true,
    editable: false,

    constructor: function(config) {
        if(config.storeOptionsAreSpecial == true) {
            var mapper = function(i) {
                if(Ext.isEmpty(i)) {
                    return [i, window.NO_BREAK_SPACE];
                } else {
                    return [i, Ext.String.htmlEncode(i)];
                }
            };
            config.store = Ext.Array.map(config.store, mapper);
        }
        this.callParent([config]);
    },

    initComponent: function() {
        this.callParent();

        if(this.storeOptionsAreSpecial == true) {
            this.displayTpl = Ext.create('Ext.XTemplate',
                '<tpl for=".">' +
                '{[typeof values === "string" ? values : values["' + this.valueField + '"]]}' +
                '<tpl if="xindex < xcount">' + this.delimiter + '</tpl>' +
                '</tpl>'
                );
        }
    }
});

// feature idea to enable Ajax loading and then the content
// cache would actually make sense. Should we dictate that they use
// data or support raw html as well?

/**
 * @class Ext.ux.RowExpander
 * @extends Ext.AbstractPlugin
 * Plugin (ptype = 'rowexpander') that adds the ability to have a Column in a grid which enables
 * a second row body which expands/contracts.  The expand/contract behavior is configurable to react
 * on clicking of the column, double click of the row, and/or hitting enter while a row is selected.
 *
 * @ptype rowexpander
 */
Ext.define('Ext.ux.RowExpander', {
    extend: 'Ext.AbstractPlugin',

    requires: [
        'Ext.grid.feature.RowBody',
        'Ext.grid.feature.RowWrap'
    ],

    alias: 'plugin.rowexpander',

    rowBodyTpl: null,

    /**
     * @cfg {Boolean} expandOnEnter
     * <tt>true</tt> to toggle selected row(s) between expanded/collapsed when the enter
     * key is pressed (defaults to <tt>true</tt>).
     */
    expandOnEnter: true,

    /**
     * @cfg {Boolean} expandOnDblClick
     * <tt>true</tt> to toggle a row between expanded/collapsed when double clicked
     * (defaults to <tt>true</tt>).
     */
    expandOnDblClick: true,

    /**
     * @cfg {Boolean} selectRowOnExpand
     * <tt>true</tt> to select a row when clicking on the expander icon
     * (defaults to <tt>false</tt>).
     */
    selectRowOnExpand: false,

    rowBodyTrSelector: '.x-grid-rowbody-tr',
    rowBodyHiddenCls: 'x-grid-row-body-hidden',
    rowCollapsedCls: 'x-grid-row-collapsed',



    renderer: function(value, metadata, record, rowIdx, colIdx) {
        if (colIdx === 0) {
            metadata.tdCls = 'x-grid-td-expander';
        }
        return '<div class="x-grid-row-expander">&#160;</div>';
    },

    /**
     * @event expandbody
     * <b<Fired through the grid's View</b>
     * @param {HTMLElement} rowNode The &lt;tr> element which owns the expanded row.
     * @param {Ext.data.Model} record The record providing the data.
     * @param {HTMLElement} expandRow The &lt;tr> element containing the expanded data.
     */
    /**
     * @event collapsebody
     * <b<Fired through the grid's View.</b>
     * @param {HTMLElement} rowNode The &lt;tr> element which owns the expanded row.
     * @param {Ext.data.Model} record The record providing the data.
     * @param {HTMLElement} expandRow The &lt;tr> element containing the expanded data.
     */

    constructor: function() {
        this.callParent(arguments);
        var grid = this.getCmp();
        this.recordsExpanded = {};
        // <debug>
        if (!this.rowBodyTpl) {
            Ext.Error.raise("The 'rowBodyTpl' config is required and is not defined.");
        }
        // </debug>
        // TODO: if XTemplate/Template receives a template as an arg, should
        // just return it back!
        var rowBodyTpl = Ext.create('Ext.XTemplate', this.rowBodyTpl),
            features = [{
                ftype: 'rowbody',
                columnId: this.getHeaderId(),
                recordsExpanded: this.recordsExpanded,
                rowBodyHiddenCls: this.rowBodyHiddenCls,
                rowCollapsedCls: this.rowCollapsedCls,
                getAdditionalData: this.getRowBodyFeatureData,
                getRowBodyContents: function(data) {
                    return rowBodyTpl.applyTemplate(data);
                }
            },{
                ftype: 'rowwrap'
            }];

        if (grid.features) {
            grid.features = features.concat(grid.features);
        } else {
            grid.features = features;
        }

        // NOTE: features have to be added before init (before Table.initComponent)
    },

    init: function(grid) {
        this.callParent(arguments);
        this.grid = grid;
        // Columns have to be added in init (after columns has been used to create the
        // headerCt). Otherwise, shared column configs get corrupted, e.g., if put in the
        // prototype.
        this.addExpander();
        grid.on('render', this.bindView, this, {single: true});
        grid.on('reconfigure', this.onReconfigure, this);
    },
    
    onReconfigure: function(){
        this.addExpander();
    },
    
    addExpander: function(){
        this.grid.headerCt.insert(0, this.getHeaderConfig());
    },

    getHeaderId: function() {
        if (!this.headerId) {
            this.headerId = Ext.id();
        }
        return this.headerId;
    },

    getRowBodyFeatureData: function(data, idx, record, orig) {
        var o = Ext.grid.feature.RowBody.prototype.getAdditionalData.apply(this, arguments),
            id = this.columnId;
        o.rowBodyColspan = o.rowBodyColspan - 1;
        o.rowBody = this.getRowBodyContents(data);
        o.rowCls = this.recordsExpanded[record.internalId] ? '' : this.rowCollapsedCls;
        o.rowBodyCls = this.recordsExpanded[record.internalId] ? '' : this.rowBodyHiddenCls;
        o[id + '-tdAttr'] = ' valign="top" rowspan="2" ';
        if (orig[id+'-tdAttr']) {
            o[id+'-tdAttr'] += orig[id+'-tdAttr'];
        }
        return o;
    },

    bindView: function() {
        var view = this.getCmp().getView(),
            viewEl;

        if (!view.rendered) {
            view.on('render', this.bindView, this, {single: true});
        } else {
            viewEl = view.getEl();
            if (this.expandOnEnter) {
                this.keyNav = Ext.create('Ext.KeyNav', viewEl, {
                    'enter' : this.onEnter,
                    scope: this
                });
            }
            if (this.expandOnDblClick) {
                view.on('itemdblclick', this.onDblClick, this);
            }
            this.view = view;
        }
    },

    onEnter: function(e) {
        var view = this.view,
            ds   = view.store,
            sm   = view.getSelectionModel(),
            sels = sm.getSelection(),
            ln   = sels.length,
            i = 0,
            rowIdx;

        for (; i < ln; i++) {
            rowIdx = ds.indexOf(sels[i]);
            this.toggleRow(rowIdx);
        }
    },

    toggleRow: function(rowIdx) {
        var view = this.view,
            rowNode = view.getNode(rowIdx),
            row = Ext.get(rowNode),
            nextBd = Ext.get(row).down(this.rowBodyTrSelector),
            record = view.getRecord(rowNode),
            grid = this.getCmp();

        if (row.hasCls(this.rowCollapsedCls)) {
            row.removeCls(this.rowCollapsedCls);
            nextBd.removeCls(this.rowBodyHiddenCls);
            this.recordsExpanded[record.internalId] = true;
            view.refreshSize();
            view.fireEvent('expandbody', rowNode, record, nextBd.dom);
        } else {
            row.addCls(this.rowCollapsedCls);
            nextBd.addCls(this.rowBodyHiddenCls);
            this.recordsExpanded[record.internalId] = false;
            view.refreshSize();
            view.fireEvent('collapsebody', rowNode, record, nextBd.dom);
        }
    },

    onDblClick: function(view, cell, rowIdx, cellIndex, e) {
        this.toggleRow(rowIdx);
    },

    getHeaderConfig: function() {
        var me                = this,
            toggleRow         = Ext.Function.bind(me.toggleRow, me),
            selectRowOnExpand = me.selectRowOnExpand;

        return {
            id: this.getHeaderId(),
            width: 24,
            sortable: false,
            resizable: false,
            draggable: false,
            hideable: false,
            menuDisabled: true,
            cls: Ext.baseCSSPrefix + 'grid-header-special',
            renderer: function(value, metadata) {
                metadata.tdCls = Ext.baseCSSPrefix + 'grid-cell-special';

                return '<div class="' + Ext.baseCSSPrefix + 'grid-row-expander">&#160;</div>';
            },
            processEvent: function(type, view, cell, recordIndex, cellIndex, e) {
                if (type == "mousedown" && e.getTarget('.x-grid-row-expander')) {
                    var row = e.getTarget('.x-grid-row');
                    toggleRow(row);
                    return selectRowOnExpand;
                }
            }
        };
    }
});

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
            header: 'View In IMPC',
            dataIndex: 'marker_symbol',
            readOnly: true,
            renderer: function (symbol, metaData, record) {
                var mgi_accession_id = record.get('mgi_accession_id');
                if (mgi_accession_id != '') {
                  return Ext.String.format('<a href="https://www.mousephenotype.org/data/genes/{0}">{1}</a>', mgi_accession_id, symbol);
                } else {
                  return Ext.String.format('{0}', symbol);
                }
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

Ext.define('Imits.widget.SimpleCheckbox', {
    extend: 'Ext.form.field.Checkbox',
    alias: 'widget.simplecheckbox',

    editor: {
        xtype: 'checkbox',
        cls: 'x-grid-checkheader-editor'
    },

    renderer: function (value) {
        var classes = "x-grid-checkheader";
        if(value === true) {
            classes += ' x-grid-checkheader-checked';
        }
        return "<div class=\"" + classes + "\"></div>";
    },

    filter: {
        type: 'boolean',
        defaultValue: null
    }

});

// gene grid with edit functionality
Ext.define('Imits.widget.GeneGrid', {
    extend: 'Imits.widget.GeneGridCommon',
    requires: [
    'Imits.model.Gene',
    'Imits.widget.grid.RansackFiltersFeature',
    'Imits.widget.SimpleCombo',
    'Ext.ux.RowExpander',
    'Imits.widget.SimpleCheckbox'
    ],
    selModel: Ext.create('Ext.selection.CheckboxModel'),
    features: [
    {
        ftype: 'ransack_filters',
        local: false
    }
    ],
    // extends the geneColumns in GeneGridCommon. These column should be independent from the GeneGridCommon (read only grid). columns common to read only grid and editable grid should be added to GeneGridCommon.
    additionalColumns: [
                        {'position': 4,
                          'data': { header: 'Non-Assigned Plans',
                                    dataIndex: 'non_assigned_mi_plans',
                                    readOnly: true,
                                    sortable: false,
                                    width: 250,
                                    flex: 1,
                                    xtype: 'templatecolumn',
                                    tpl: new Ext.XTemplate(
                                        '<tpl for="non_assigned_mi_plans">',
                                        '<a href="' + window.basePath + '/mi_plans/{[values["id"]]}" target="_blank">{[this.prettyPrintMiPlan(values)]}</a></br>',
                                        '</tpl>',
                                        {
                                            prettyPrintMiPlan: printMiPlanString
                                        }
                                        )
                                   }
                         },
                         {'position': 5,
                         'data': {header: 'Assigned Plans',
                                  dataIndex: 'assigned_mi_plans',
                                  readOnly: true,
                                  sortable: false,
                                  width: 180,
                                  flex: 1,
                                  xtype: 'templatecolumn',
                                  tpl: new Ext.XTemplate(
                                      '<tpl for="assigned_mi_plans">',
                                      '<a href="' + window.basePath + '/mi_plans/{[values["id"]]}" target="_blank">{[this.prettyPrintMiPlan(values)]}</a></br>',
                                      '</tpl>',
                                      {
                                          prettyPrintMiPlan: printMiPlanString
                                      }
                                      )
                                  }
                        },
                        {'position': 6,
                         'data': {header: 'Aborted MIs',
                                  dataIndex: 'pretty_print_aborted_mi_attempts',
                                  readOnly: true,
                                  sortable: false,
                                  width: 180,
                                  flex: 1,
                                  xtype: 'templatecolumn',
                                  tpl: new Ext.XTemplate(
                                      '<tpl for="this.processedMIs(pretty_print_aborted_mi_attempts)">',
                                      '<a href="' + window.basePath +  '/mi_attempts?q[terms]={parent.marker_symbol}&q[production_centre_name]={production_centre}" target="_blank">[{consortium}:{production_centre}:{count}]</a></br>',
                                      '</tpl>',
                                      {
                                          processedMIs: splitResultString
                                      }
                                     )
                                 }
                        },
                        {'position': 7,
                         'data': {header: 'MIs in Progress',
                                  dataIndex: 'pretty_print_mi_attempts_in_progress',
                                  readOnly: true,
                                  sortable: false,
                                  width: 180,
                                  flex: 1,
                                  xtype: 'templatecolumn',
                                  tpl: new Ext.XTemplate(
                                      '<tpl for="this.processedMIs(pretty_print_mi_attempts_in_progress)">',
                                      '<a href="' + window.basePath + '/mi_attempts?q[terms]={parent.marker_symbol}&q[production_centre_name]={production_centre}" target="_blank">[{consortium}:{production_centre}:{count}]</a></br>',
                                      '</tpl>',
                                      {
                                          processedMIs: splitResultString
                                      }
                                      )
                                 }
                        },
                        {'position': 8,
                         'data': {header: 'Genotype Confirmed MIs',
                                 dataIndex: 'pretty_print_mi_attempts_genotype_confirmed',
                                 readOnly: true,
                                 sortable: false,
                                 width: 180,
                                 flex: 1,
                                 xtype: 'templatecolumn',
                                 tpl: new Ext.XTemplate(
                                     '<tpl for="this.processedMIs(pretty_print_mi_attempts_genotype_confirmed)">',
                                     '<a href="' + window.basePath + '/mi_attempts?q[terms]={parent.marker_symbol}&q[production_centre_name]={production_centre}" target="_blank">[{consortium}:{production_centre}:{count}]</a></br>',
                                     '</tpl>',
                                     {
                                          processedMIs: splitResultString
                                     }
                                 )
                                }
                        },
                        {'position': 9,
                         'data': {header: 'Phenotype Attempts',
                                  dataIndex: 'pretty_print_phenotype_attempts',
                                  readOnly: true,
                                  sortable: false,
                                  width: 180,
                                  flex: 1,
                                  xtype: 'templatecolumn',
                                  tpl: new Ext.XTemplate(
                                      '<tpl for="this.processedMIs(pretty_print_phenotype_attempts)">',
                                      '<a href="' + window.basePath + '/open/phenotype_attempts?q[terms]={parent.marker_symbol}&q[production_centre_name]={production_centre}" target="_blank">[{consortium}:{production_centre}:{count}]</a></br>',
                                      '</tpl>',
                                      {
                                          processedMIs: splitResultString
                                      }
                                  )
                                 }
                        },
                        {'position': 1 ,
                         'data': {header: 'Tree',
                                  readOnly: true,
                                  renderer: function (value, metaData, record) {
                                      var mgiId = record.get('mgi_accession_id');
                                      var iconURL = '<img src="' + window.basePath + '/images/icons/application_side_tree.png" alt="Blah"/>';
                                      return Ext.String.format('<a href="{0}/genes/{1}/relationship_tree">{2}</a>', window.basePath, mgiId, iconURL);
                                  },
                                  width: 40,
                                  sortable: false
                                  }
                        },
                        {'position': 1,
                         'data': {header: 'Production History',
                                 dataIndex: 'production_history_link',
                                 renderer: function (value, metaData, record) {
                                     var geneId = record.getId();
                                     return Ext.String.format('<a href="{0}/genes/{1}/network_graph">Production Graph</a>', window.basePath, geneId);
                                 },
                                 sortable: false
                                 }
                        }

    ],

           /** @private **/
    createComboBox: function(id, label, labelWidth, store, includeBlank, isHidden) {
        if(includeBlank) {
            store = Ext.Array.merge([null], store);
        }
        return Ext.create('Imits.widget.SimpleCombo', {
            id: id + 'Combobox',
            store: store,
            fieldLabel: label,
            labelAlign: 'right',
            labelWidth: labelWidth,
            storeOptionsAreSpecial: true,
            hidden: isHidden
        });
    },

    createCheckBox: function(id, label, labelWidth, isHidden) {
        return Ext.create('Imits.widget.SimpleCheckbox', {
            id: id + 'Checkbox',
            fieldLabel: label,
            labelAlign: 'right',
            labelWidth: labelWidth,
            hidden: isHidden
        });
    },

    registerInterestHandler: function() {
        var grid                 = this;
        var geneCounter          = 0;
        var selectedGenes        = grid.getSelectionModel().selected;
        var failedGenes          = [];
        var consortiumName       = grid.consortiumCombo.getSubmitValue();
        var productionCentreName = grid.centreCombo.getSubmitValue();
        var subProjectName       = grid.subprojectCombo.getSubmitValue();
        var PhenotypeOnly        = grid.phenotypeonlyCheck.getSubmitValue() || false;
        var Crispr               = grid.crisprCheck.getSubmitValue() || false;
        var priorityName         = grid.priorityCombo.getSubmitValue();
        var isBespokeAllele      = grid.isbespokealleleCheck.getSubmitValue() || false;
        var isConditionalAllele  = grid.isconditionalalleleCheck.getSubmitValue() || false;
        var isDeletionAllele     = grid.isdeletionalleleCheck.getSubmitValue() || false;
        var isCreKnockInAllele   = grid.iscreknockinalleleCheck.getSubmitValue() || false;
        var isCreBacAllele       = grid.iscrebacalleleCheck.getSubmitValue() || false;
        var conditionalTm1c      = grid.conditionaltm1cCheck.getSubmitValue() || false;
        var pointMutation        = grid.pointmutationCheck.getSubmitValue() || false;
        var conditionalPointMutation = grid.conditionalpointmutationCheck.getSubmitValue() || false;

        if(selectedGenes.length == 0) {
            alert('You must select some genes to register interest in');
            return;
        }
        if(consortiumName == null) {
            alert('You must select a consortium');
            return;
        }
        if(priorityName == null) {
            alert('You must selct a priority');
            return;
        }

        grid.setLoading(true);

        selectedGenes.each(function(geneRow) {
            var markerSymbol = geneRow.raw['marker_symbol'];
            var miPlan = Ext.create('Imits.model.MiPlan', {
                'marker_symbol'          : markerSymbol,
                'consortium_name'        : consortiumName,
                'production_centre_name' : productionCentreName,
                'sub_project_name'       : subProjectName,
                'phenotype_only'         : PhenotypeOnly,
                'mutagenesis_via_crispr_cas9' : Crispr,
                'priority_name'          : priorityName,
                'is_bespoke_allele'      : isBespokeAllele,
                'is_conditional_allele'  : isConditionalAllele,
                'is_deletion_allele'     : isDeletionAllele,
                'is_cre_knock_in_allele' : isCreKnockInAllele,
                'is_cre_bac_allele'      : isCreBacAllele,
                'conditional_tm1c'       : conditionalTm1c,
                'point_mutation'         : pointMutation,
                'conditional_point_mutation' : conditionalPointMutation
            });
            miPlan.save({
                failure: function() {
                    failedGenes.push(markerSymbol);
                },
                callback: function() {
                    geneCounter++;
                    if( geneCounter == selectedGenes.length ) {
                        if( !Ext.isEmpty(failedGenes) ) {
                            alert('An error occured trying to register interest on the following genes: ' + failedGenes.join(', ') + '. Please try again.');
                        }

                        grid.reloadStore();
                        grid.setLoading(false);
                    }
                }
            });
        });
    },
    initComponent: function() {
        var grid = this;

        // Adds additional columns
        Ext.Array.each(grid.additionalColumns, function(column) {
            grid.addColumn(column['data'], column['position']);
        });
        grid.callParent();

        var isSubProjectHidden = true;
        if(window.CAN_SEE_SUB_PROJECT) {
            isSubProjectHidden = false;
        }

        // Add the top (gene selection) toolbar
        grid.consortiumCombo  = grid.createComboBox('consortium', 'Consortium', 65, window.CONSORTIUM_OPTIONS, false, false);
        grid.centreCombo      = grid.createComboBox('production_centre', 'Production Centre', 100, window.CENTRE_OPTIONS, true, false);
        grid.subprojectCombo  = grid.createComboBox('sub_project', 'Sub Project', 65, window.SUB_PROJECT_OPTIONS, false, isSubProjectHidden);
        grid.priorityCombo    = grid.createComboBox('priority', 'Priority', 47, window.PRIORITY_OPTIONS, false, false);
        grid.phenotypeonlyCheck     = grid.createCheckBox('phenotype_only', 'Phenotype Only', 95, false);
        grid.crisprCheck              = grid.createCheckBox('mutagenesis_via_crispr_cas9', 'Mutagenesis Via Crispr/Cas9?', 95, false);
        grid.isbespokealleleCheck     = grid.createCheckBox('is_bespoke_allele', 'Bespoke', 52, false);
        grid.isconditionalalleleCheck = grid.createCheckBox('is_conditional_allele', 'Knockout First Tm1a', 120, false);
        grid.isdeletionalleleCheck    = grid.createCheckBox('is_deletion_allele', 'Deletion', 57, false);
        grid.iscreknockinalleleCheck  = grid.createCheckBox('is_cre_knock_in_allele', 'Cre Knock In', 80, false);
        grid.iscrebacalleleCheck      = grid.createCheckBox('is_cre_bac_allele', 'Cre Bac', 55, false);
        grid.conditionaltm1cCheck      = grid.createCheckBox('conditional_tm1c', 'Conditional tm1c', 100, false);
        grid.pointmutationCheck      = grid.createCheckBox('point_mutation', 'Point Mutation', 80, false);
        grid.conditionalpointmutationCheck      = grid.createCheckBox('conditional_point_mutation', 'Conditional Point Mutation', 135, false);

        grid.addDocked(Ext.create('Ext.toolbar.Toolbar', {
            dock: 'top',
            items: [
            grid.consortiumCombo,
            grid.centreCombo,
            grid.subprojectCombo,
            grid.priorityCombo,
            grid.phenotypeonlyCheck,
            grid.crisprCheck
            ]
        }));

        grid.addDocked(Ext.create('Ext.toolbar.Toolbar', {
            dock: 'top',
            items: [
            grid.isbespokealleleCheck,
            grid.isconditionalalleleCheck,
            grid.conditionaltm1cCheck,
            grid.isdeletionalleleCheck,
            grid.iscreknockinalleleCheck,
            grid.iscrebacalleleCheck,
            grid.pointmutationCheck,
            grid.conditionalpointmutationCheck,
            '',
            '',
            {
                id: 'register_interest_button',
                text: 'Register Interest',
                cls:'x-btn-text-icon',
                iconCls: 'icon-add',
                grid: grid,
                handler: function() {
                    grid.registerInterestHandler();
                }
            }
            ]
        }));
    }
});

// gene grid read only
Ext.define('Imits.widget.GeneGridGeneral', {
    extend: 'Imits.widget.GeneGridCommon',

    // extends the geneColumns in GeneGridCommon. These column should be independent from the GeneGrid (edit grid). columns common to read only grid and editable grid should be added to GeneGridCommon.
    additionalColumns: [
                         {'position': 4,
                          'data': { header: 'Non-Assigned Plans',
                                    dataIndex: 'non_assigned_mi_plans',
                                    readOnly: true,
                                    sortable: false,
                                    width: 250,
                                    flex: 1,
                                    xtype: 'templatecolumn',
                                    tpl: new Ext.XTemplate(
                                        '<tpl for="non_assigned_mi_plans">',
                                        '<a href="' + window.basePath + '/open/mi_plans/{[values["id"]]}" target="_blank">{[this.prettyPrintMiPlan(values)]}</a></br>',
                                        '</tpl>',
                                        {
                                            prettyPrintMiPlan: printMiPlanString
                                        }
                                        )
                                   }
                         },
                         {'position': 5,
                         'data': {header: 'Assigned Plans',
                                  dataIndex: 'assigned_mi_plans',
                                  readOnly: true,
                                  sortable: false,
                                  width: 180,
                                  flex: 1,
                                  xtype: 'templatecolumn',
                                  tpl: new Ext.XTemplate(
                                      '<tpl for="assigned_mi_plans">',
                                      '<a href="' + window.basePath + '/open/mi_plans/{[values["id"]]}" target="_blank">{[this.prettyPrintMiPlan(values)]}</a></br>',
                                      '</tpl>',
                                      {
                                          prettyPrintMiPlan: printMiPlanString
                                      }
                                      )
                                  }
                        },
                        {'position': 6,
                         'data': {header: 'Aborted MIs',
                                  dataIndex: 'pretty_print_aborted_mi_attempts',
                                  readOnly: true,
                                  sortable: false,
                                  width: 180,
                                  flex: 1,
                                  xtype: 'templatecolumn',
                                  tpl: new Ext.XTemplate(
                                      '<tpl for="this.processedMIs(pretty_print_aborted_mi_attempts)">',
                                      '<a href="' + window.basePath +  '/open/mi_attempts?q[terms]={parent.marker_symbol}&q[production_centre_name]={production_centre}" target="_blank">[{consortium}:{production_centre}:{count}]</a></br>',
                                      '</tpl>',
                                      {
                                          processedMIs: splitResultString
                                      }
                                     )
                                 }
                        },
                        {'position': 7,
                         'data': {header: 'MIs in Progress',
                                  dataIndex: 'pretty_print_mi_attempts_in_progress',
                                  readOnly: true,
                                  sortable: false,
                                  width: 180,
                                  flex: 1,
                                  xtype: 'templatecolumn',
                                  tpl: new Ext.XTemplate(
                                      '<tpl for="this.processedMIs(pretty_print_mi_attempts_in_progress)">',
                                      '<a href="' + window.basePath + '/open/mi_attempts?q[terms]={parent.marker_symbol}&q[production_centre_name]={production_centre}" target="_blank">[{consortium}:{production_centre}:{count}]</a></br>',
                                      '</tpl>',
                                      {
                                          processedMIs: splitResultString
                                      }
                                      )
                                 }
                        },
                        {'position': 8,
                         'data': {header: 'Genotype Confirmed MIs',
                                 dataIndex: 'pretty_print_mi_attempts_genotype_confirmed',
                                 readOnly: true,
                                 sortable: false,
                                 width: 180,
                                 flex: 1,
                                 xtype: 'templatecolumn',
                                 tpl: new Ext.XTemplate(
                                     '<tpl for="this.processedMIs(pretty_print_mi_attempts_genotype_confirmed)">',
                                     '<a href="' + window.basePath + '/open/mi_attempts?q[terms]={parent.marker_symbol}&q[production_centre_name]={production_centre}" target="_blank">[{consortium}:{production_centre}:{count}]</a></br>',
                                     '</tpl>',
                                     {
                                          processedMIs: splitResultString
                                     }
                                 )
                                }
                        },
                        {'position': 9,
                         'data': {header: 'Phenotype Attempts',
                                  dataIndex: 'pretty_print_phenotype_attempts',
                                  readOnly: true,
                                  sortable: false,
                                  width: 180,
                                  flex: 1,
                                  xtype: 'templatecolumn',
                                  tpl: new Ext.XTemplate(
                                      '<tpl for="this.processedMIs(pretty_print_phenotype_attempts)">',
                                      '<a href="' + window.basePath + '/open/phenotype_attempts?q[terms]={parent.marker_symbol}&q[production_centre_name]={production_centre}" target="_blank">[{consortium}:{production_centre}:{count}]</a></br>',
                                      '</tpl>',
                                      {
                                          processedMIs: splitResultString
                                      }
                                  )
                                 }
                        },
                        {'position': 1,
                         'data': {header: 'Production History',
                                 dataIndex: 'production_history_link',
                                 renderer: function (value, metaData, record) {
                                     var geneId = record.getId();
                                     return Ext.String.format('<a href="{0}/open/genes/{1}/network_graph">Production Graph</a>', window.basePath, geneId);
                                 },
                                 sortable: false
                                 }
                        },
           ],

    initComponent: function() {
        var grid = this;

        // Adds additional columns
        Ext.Array.each(grid.additionalColumns, function(column) {
            grid.addColumn(column['data'], column['position']);
        });
        grid.callParent();
    }
})

Ext.define('Imits.widget.GeneRelationshipTree', {
    extend: 'Ext.tree.Panel',

    requires: [
        'Ext.data.TreeStore',
        'Ext.tree.plugin.TreeViewDragDrop'
    ],

    mixins: [
        'Imits.widget.ManageResizeWithBrowserFrame'
    ],

    viewConfig: {
        plugins: {
            ptype: 'treeviewdragdrop'
        }
    },

    columns: [
        {
            xtype: 'treecolumn',
            dataIndex: 'name',
            text: '&nbsp;',
            flex: 1
        },
        {
            text: 'ID',
            dataIndex: 'id',
            hidden: true
        },
        {
            text: 'Status',
            dataIndex: 'status',
            width: 200
        },
        {
            text: 'Colony name',
            dataIndex: 'colony_name',
            width: 200
        },
        {
            text: 'Sub-project',
            dataIndex: 'sub_project_name',
            width: 200
        }
    ],

    handleMove: function (node, oldParent, newParent) {
        var self = this, newPlanData = newParent.data;

        if (newPlanData.type !== 'MiPlan') {
            Ext.MessageBox.alert('Alert', Ext.String.format('Can only drag onto a Plan'));
        } else if (newPlanData.id === node.data.mi_plan_id) {
            Ext.MessageBox.alert('Alert', Ext.String.format('This {0} already belongs to {1} and {2}',
                                                            node.data.name,
                                                            newPlanData.consortium_name,
                                                            newPlanData.production_centre_name));
        } else {
            var message =
                Ext.String.format("Updating {0} {1}<br>" +
                                  "Old consortium / production centre / plan ID: {2} / {3} / {4}<br>" +
                                  "New consortium / production centre / plan ID: {5} / {6} / {7}<br>",
                                  node.data.name,
                                  node.data.colony_name,
                                  node.data.consortium_name,
                                  node.data.production_centre_name,
                                  node.data.mi_plan_id,
                                  newPlanData.consortium_name,
                                  newPlanData.production_centre_name,
                                  newPlanData.id);
            Ext.MessageBox.confirm('Note', message, function (button) {
                if (button === 'yes') {
                    var modelClass;
                    if (node.data.type === 'MiAttempt') {
                        modelClass = Imits.model.MiAttempt;
                    } else if (node.data.type === 'PhenotypeAttempt') {
                        modelClass = Imits.model.PhenotypeAttempt;
                    } else {
                        throw('Unknown model');
                    }

                    modelClass.load(node.data.id, {
                        success: function (object) {
                            object.set('mi_plan_id', newPlanData.id);
                            object.save({
                                success: function () {
                                    self.getStore().reload();
                                }
                            });
                        }
                    });
                }
            });
        }
    },

    initComponent: function () {
        var self = this;

        self.callParent();

        self.addListener('load', function (thing, records, successful) {
            if (successful) {
                self.expandAll();
            }
        });

        self.addListener('beforeitemmove', function (node, oldParent, newParent, index) {
            if ( ['MiPlan', 'Centre', 'Consortium'].indexOf(newParent.data.type) !== -1 ) {
                self.handleMove(node, oldParent, newParent);
            }

            return false;
        });
    },

    title: '&nbsp;',
    store: Ext.create('Ext.data.TreeStore', {
        fields: [
            {name: 'id', type: 'integer'},
            {name: 'mi_plan_id', type: 'integer'},
            {name: 'name', type: 'string'},
            {name: 'type', type: 'string'},
            {name: 'status', type: 'string'},
            {name: 'colony_name', type: 'string'},
            {name: 'consortium_name', type: 'string'},
            {name: 'production_centre_name', type: 'string'},
            {name: 'sub_project_name', type: 'string'}
        ],

        proxy: {
            type: 'ajax',
            url: (function () {
                if (window.GENE) {
                    return window.basePath + '/genes/' + window.GENE.mgi_accession_id + '/relationship_tree.json';
                } else {
                    return '';
                }
            }())
        }

    }),
    rootVisible: false,
    useArrows: true
});

Ext.define('Imits.widget.grid.BoolGridColumn', {
    extend: 'Ext.grid.Column',
    alias: 'widget.boolgridcolumn',

    editor: {
        xtype: 'checkbox',
        cls: 'x-grid-checkheader-editor'
    },

    renderer: function (value) {
        var classes = "x-grid-checkheader";
        if(value === true) {
            classes += ' x-grid-checkheader-checked';
        }
        return "<div class=\"" + classes + "\"></div>";
    },

    filter: {
        type: 'boolean',
        defaultValue: null
    }
});

Ext.define('Imits.widget.grid.MiAttemptRansackFiltersFeature', {
    extend: 'Imits.widget.grid.RansackFiltersFeature',
    alias: 'feature.mi_attempt_ransack_filters',

    encode: false,

    buildQuery: function (filters) {
        var params = this.callParent([filters]);
        var terms = window.MI_ATTEMPT_SEARCH_PARAMS.terms;

        if(!Ext.isEmpty(terms)) {
            terms = terms.split("\n");
            params['q[mi_plan_gene_marker_symbol_or_es_cell_name_or_external_ref_ci_in][]'] = terms;
        }

        return params;
    }
});

Ext.define('Imits.widget.grid.PhenotypeAttemptRansackFiltersFeature', {
    extend: 'Imits.widget.grid.RansackFiltersFeature',
    alias: 'feature.phenotype_attempt_ransack_filters',

    encode: false,

    buildQuery: function (filters) {
        var params = this.callParent([filters]);
        var terms = window.PHENOTYPE_ATTEMPT_SEARCH_PARAMS.terms;

        if(!Ext.isEmpty(terms)) {
            terms = terms.split("\n");
            params['q[colony_name_or_mi_plan_gene_marker_symbol_or_parent_colony_name_ci_in][]'] = terms;
        }

        return params;
    }
});

Ext.define('Imits.widget.grid.SimpleDateColumn', {
    extend: 'Ext.grid.column.Date',
    alias: 'widget.simpledatecolumn',

    format: 'd-m-Y',
    editor: {
        xtype: 'datefield',
        format: 'd-m-Y'
    },
    filter: {
        type: 'date'
    }
});

Ext.define('Imits.widget.SimpleNumberField', {
    extend: 'Ext.form.field.Number',
    alias: 'widget.simplenumberfield',
    minValue: 0,
    hideTrigger: true,
    keyNavEnabled: false,
    mouseWheelEnabled: false,
    allowDecimals: false
});

Ext.define('Imits.widget.QCCombo', {
    extend: 'Imits.widget.SimpleCombo',
    alias: 'widget.qccombo',
    store: window.MI_ATTEMPT_QC_OPTIONS
});

function splitString(prettyPrintDistributionCentres) {
    var distributionCentres = [];
    Ext.Array.each(prettyPrintDistributionCentres.split(', '), function(dc) {
        distributionCentres.push({
            distributionCentre: dc
        });
    });

    return distributionCentres;
}

// traps the selection of new column sets via the grid menu buttons
function onItemClick(item){
    function intensiveOperation() {
        var columnsToShow = grid.views[item.text];

        if (typeof columnsToShow == 'undefined') {
            alert('Unrecognised column filter: ' + item.text);
        } else {
            // filter rows on cas9 flag
            switch(item.text) {
                case 'Summary':
                    // filter cas9 inactivated
                    grid.deactivateCrisprFilter();
                    break;
                case 'ES Cell Summary':
                case 'ES Cell Transfer Details':
                case 'ES Cell Litter Details':
                case 'ES Cell Chimera Mating Details':
                case 'ES Cell QC Details':
                case 'ES Cell All Details':
                    // filter cas9 off
                    grid.activateCrisprFilterWithValue(false);
                    break;
                case 'Crispr Summary':
                case 'Crispr Transfer Details':
                case 'Crispr Founder Details':
                case 'Crispr F1 Details':
                case 'Crispr QC Details':
                case 'Crispr All Details':
                    // filter cas9 on
                    grid.activateCrisprFilterWithValue(true);
                    break;
                default:
                    break;
            };

            // select which columns to show
            var columnsToShowHash = {};
            Ext.each(columnsToShow, function(columnToShow) {
                columnsToShowHash[columnToShow] = true;
            });

            grid.reconfigure(null, grid.initialConfig.columns)

            // setVisible method is slow, so suspend layouts then do all the setVisibles then resume
            Ext.suspendLayouts();
            Ext.each(grid.columns, function(column) {
                if(column.dataIndex in columnsToShowHash) {
                    column.setVisible(true);
                } else {
                    column.setVisible(false);
                }
            });

            // move columns arround if needed
//            switch(item.text) {
//                case 'Summary':
//                    grid.moveColumnToIndex("mi_plan_mutagenesis_via_crispr_cas9", 11);
//                    break;
//                case 'ES Cell Transfer Details':
//                case 'ES Cell Litter Details':
//                case 'ES Cell Chimera Mating Details':
//                case 'ES Cell QC Details':
//                case 'ES Cell All Details':
//                    break;
//                default:
//                    break;
//            };

            Ext.resumeLayouts(true);

            grid.setTitle('Micro-Injection Attempts - ' + item.text);
        }

        mask.hide();
        Ext.getBody().removeCls('wait');
    }

    var mask = new Ext.LoadMask(grid.getEl(),
    {
        msg: 'Please wait&hellip;',
        removeMask: true
    });

    Ext.getBody().addCls('wait');
    mask.show();
    setTimeout(intensiveOperation, 100);
}

Ext.define('Imits.widget.MiGridCommon', {
    extend: 'Imits.widget.Grid',

    requires: [
    'Imits.model.MiAttempt',
    'Imits.widget.SimpleNumberField',
    'Imits.widget.SimpleCombo',
    'Imits.widget.QCCombo',
    'Imits.widget.grid.BoolGridColumn',
    'Imits.widget.grid.MiAttemptRansackFiltersFeature',
    'Imits.widget.grid.SimpleDateColumn',
    'Imits.Util',
    'Ext.util.HashMap'
    ],

    title: 'Micro-Injection Attempts - Everything',
    store: {
        model: 'Imits.model.MiAttempt',
        autoLoad: true,
        autoSync: true,
        remoteSort: true,
        pageSize: 20
    },

    selType: 'rowmodel',

    features: [
    {
        ftype: 'mi_attempt_ransack_filters',
        local: false
    }
    ],

    /** @private */
    addColumnsToGroupedColumns: function(group, relative_position, new_column) {
      this.groupedColumns[group].splice(relative_position, 0, new_column)
    },

    generateColumns: function(config) {
        var columns = [];

        Ext.Object.each(this.groupedColumns, function(viewName, viewColumns) {
            Ext.Array.each(viewColumns, function(column) {
                var existing;
                Ext.each(columns, function(i) {
                    if(i.dataIndex == column.dataIndex && i.header == column.header) {
                        existing = i;
                    }
                });
                if(!existing) {
                    column.tdCls = 'column-' + column.dataIndex;
                    columns.push(column);
                }
            });
        });

        config.columns = columns;
    },

    /** @private */
    generateViews: function() {
        var views = {};

        var commonColumns       = Ext.pluck(this.groupedColumns.common, 'dataIndex');
        var esCellCommonColumns = Ext.pluck(this.groupedColumns.es_cell_common, 'dataIndex');
        var crisprCommonColumns = Ext.pluck(this.groupedColumns.crispr_common, 'dataIndex');;

        var esCellAllDetailView = [];
        var CrisprAllDetailView = [];

        // First generate the groups from the groupedColumns
        Ext.Object.each(this.groupedColumns, function(viewName, viewColumnConfigs) {
            // switch what columns are displayed based on view name
            switch(viewName) {
                case 'common':
                case 'es_cell_common':
                case 'crispr_common':
                case 'none':
                    return;
                case 'Summary':
                    var viewColumns = Ext.pluck(viewColumnConfigs, 'dataIndex');
                    views[viewName] = viewColumns;
                  break;
                case 'ES Cell Summary':
                case 'ES Cell Transfer Details':
                case 'ES Cell Litter Details':
                case 'ES Cell Chimera Mating Details':
                case 'ES Cell QC Details':
                    var viewColumns = Ext.pluck(viewColumnConfigs, 'dataIndex');
                    views[viewName] = Ext.Array.merge(commonColumns, esCellCommonColumns, viewColumns);
                    esCellAllDetailView = Ext.Array.merge(commonColumns, esCellCommonColumns, esCellAllDetailView, viewColumns);
                    break;
                case 'Crispr Summary':
                case 'Crispr Transfer Details':
                case 'Crispr Founder Details':
                case 'Crispr F1 Details':
                case 'Crispr QC Details':
                    var viewColumns = Ext.pluck(viewColumnConfigs, 'dataIndex');
                    views[viewName] = Ext.Array.merge(commonColumns, crisprCommonColumns, viewColumns);
                    CrisprAllDetailView = Ext.Array.merge(commonColumns, crisprCommonColumns, CrisprAllDetailView, viewColumns);
                    break;
                default:
                    return;
            }
            views['ES Cell All Details'] = esCellAllDetailView;
            views['Crispr All Details'] = CrisprAllDetailView;
        });

        var grid = this;
        Ext.Object.each(this.additionalViewColumns, function(viewName) {
            views[viewName] = Ext.Array.merge(commonColumns, grid.additionalViewColumns[viewName], views[viewName]);
        });
        this.views = views;
    },

    constructor: function(config) {
        if(config == undefined) {
            config = {};
        }
        this.generateColumns(config);
        this.generateViews();
        this.callParent([config]);
        onItemClick({text: 'Summary'});
    },

    switchViewMenuButtonConfig: function(text, menuContent) {
        var grid = this;
        return {
            text: text,
            enableToggle: true,
            allowDepress: false,
            toggleGroup: 'mi_grid_view_config',
            minWidth: 100,
            pressed: false,
            menu: menuContent,
            listeners: {
                'toggle': function(button, pressed) {
                    if(!pressed) {
                        return;
                    }
                }
            }
        };
    },

    initComponent: function() {
        var self = this;

        self.callParent();

        self.addDocked(Ext.create('Ext.toolbar.Paging', {
            store: self.getStore(),
            dock: 'bottom',
            displayInfo: true
        }));

        var everythingMenuConfig = [
            { text:'Summary', handler: onItemClick }//,
          //  { text:'Everything', handler: onItemClick }
        ];

        var esCellsMenuConfig = [
            { text:'ES Cell Summary', handler: onItemClick },
            { text:'ES Cell All Details', handler: onItemClick },
            { text:'ES Cell Transfer Details', handler: onItemClick },
            { text:'ES Cell Litter Details', handler: onItemClick },
            { text:'ES Cell Chimera Mating Details', handler: onItemClick },
            { text:'ES Cell QC Details', handler: onItemClick }
        ];

        var crisprsMenuConfig = [
            { text:'Crispr Summary', handler: onItemClick },
            { text:'Crispr All Details', handler: onItemClick },
            { text:'Crispr Transfer Details', handler: onItemClick },
            { text:'Crispr Founder Details', handler: onItemClick }//,
            // { text:'Crispr F1 Details', handler: onItemClick },
            // { text:'Crispr QC Details', handler: onItemClick },
        ];

        self.menuBtnEverything = self.switchViewMenuButtonConfig( 'Everything', everythingMenuConfig );
        self.menuBtnESCells    = self.switchViewMenuButtonConfig( 'ES Cells', esCellsMenuConfig );
        self.menuBtnCrisprs    = self.switchViewMenuButtonConfig( 'Crisprs', crisprsMenuConfig );

        self.addDocked(Ext.create('Ext.container.ButtonGroup', {
            layout: 'hbox',
            dock: 'top',
            items: [
                self.menuBtnEverything,
                self.menuBtnESCells,
                self.menuBtnCrisprs
            ]
        }));

        self.addListener('afterrender', function () {
            self.filters.createFilters();
        });
    },

    activateCrisprFilterWithValue: function(value) {
        var self = this;

        var iA = self.filters.getFilter('mi_plan_mutagenesis_via_crispr_cas9').isActivatable();
        self.filters.getFilter('mi_plan_mutagenesis_via_crispr_cas9').setValue(value);
        self.filters.getFilter('mi_plan_mutagenesis_via_crispr_cas9').setActive(true);
        if(iA === true) {
            self.getStore().reload();
        }
    },

    deactivateCrisprFilter: function() {
        var self = this;

        var iA = self.filters.getFilter('mi_plan_mutagenesis_via_crispr_cas9').isActivatable();
        self.filters.getFilter('mi_plan_mutagenesis_via_crispr_cas9').setActive(false);
        if(iA === true) {
            self.getStore().reload();
        }
    },

    findColumnIndex: function(columns, dataIndex) {
        var index;
        for (index = 0; index < columns.length; ++index) {
            if (columns[index].dataIndex == dataIndex) {
                break;
            }
        }
        return index == columns.length ? -1 : index;
    },

    moveColumnToIndex: function(columnName, newColumnIndex) {
        var self = this;
        var col_index = grid.findColumnIndex(self.headerCt.getGridColumns(), columnName);
        if (col_index != -1 && col_index != newColumnIndex) {
            self.headerCt.move(col_index, newColumnIndex);
        }
    },

    // BEGIN COLUMN DEFINITION

    groupedColumns: {
        'none': [
        {
            dataIndex: 'id',
            header: 'ID',
            readOnly: true,
            hidden: (Imits.Util.extractValueIfExistent(window.MI_ATTEMPT_SEARCH_PARAMS, 'mi_attempt_id') ? false : true),
            filter: {
                type: 'string',
                value: Imits.Util.extractValueIfExistent(window.MI_ATTEMPT_SEARCH_PARAMS, 'mi_attempt_id')
            }
        }
        ],

        'common': [
        {
            dataIndex: 'marker_symbol',
            header: 'Marker Symbol',
            width: 85,
            readOnly: true,
            sortable: false,
        },
        {
            dataIndex: 'consortium_name',
            header: 'Consortium',
            readOnly: true,
            width: 150,
            filter: {
                type: 'list',
                options: window.MI_ATTEMPT_CONSORTIUM_OPTIONS,
                value: Imits.Util.extractValueIfExistent(window.MI_ATTEMPT_SEARCH_PARAMS, 'consortium_name')
            },
            sortable: false
        },
        {
            dataIndex: 'production_centre_name',
            header: 'Production Centre',
            readOnly: true,
            filter: {
                type: 'list',
                options: window.MI_ATTEMPT_CENTRE_OPTIONS,
                value: Imits.Util.extractValueIfExistent(window.MI_ATTEMPT_SEARCH_PARAMS, 'production_centre_name')
            },
            sortable: false
        },
        {
            dataIndex: 'colony_name',
            header: 'MI External Ref/ Colony Name',
            width: 180,
            editor: 'textfield',
            filter: {
                type: 'string',
                value: Imits.Util.extractValueIfExistent(window.MI_ATTEMPT_SEARCH_PARAMS, 'colony_name')
            }
        },
        {
            dataIndex: 'status_name',
            header: 'Status',
            width: 180,
            readOnly: true,
            sortable: false,
            filter: {
                type: 'list',
                options: window.MI_ATTEMPT_STATUS_OPTIONS,
                value: Imits.Util.extractValueIfExistent(window.MI_ATTEMPT_SEARCH_PARAMS, 'status_name')
            }
        },
        {
            dataIndex: 'genotyped_confirmed_colony_names',
            header: 'Genotype Confirmed Colonies',
            width: 180,
            editor: 'textfield',
            renderer: function(value, metaData, record){
                var genotype_confirmed_colony_names = record.get('genotyped_confirmed_colony_names').toString().replace('[', '').replace(']', '').split(',');
                var textToDisplay = genotype_confirmed_colony_names.join('<br><br>')
                return textToDisplay
                },
            sortable: false
        },
        {
            dataIndex: 'genotype_confirmed_allele_symbols',
            header: 'Mouse Allele Symbol',
            width: 180,
            readOnly: true,
            renderer: function(value, metaData, record){
                var genotype_confirmed_colony_names = record.get('genotype_confirmed_allele_symbols').toString().replace('[', '').replace(']', '').split(',');
                var textToDisplay = genotype_confirmed_colony_names.join('<br><br>')
                return textToDisplay
                },
            sortable: false
        }
        ],

        'Summary': [
        {
            dataIndex: 'mi_plan_mutagenesis_via_crispr_cas9',
            header: 'CrispR Cas9',
            readOnly: true,
            sortable: false,
            filter: {
                type: 'boolean'
            }
        }
        ],
        'Crispr Summary': [],
        'ES Cell Summary': [],
        'es_cell_common': [
        {
            xtype: 'simpledatecolumn',
            dataIndex: 'mi_date',
            header: 'MI Date',
            width: 90
        },
        {
            dataIndex: 'es_cell_name',
            header: 'ES Cell',
            readOnly: true,
            width: 140,
            sortable: false,
            filter: {
                type: 'string',
                value: Imits.Util.extractValueIfExistent(window.MI_ATTEMPT_SEARCH_PARAMS, 'es_cell_name')
            }
        },
        {
            dataIndex: 'es_cell_allele_symbol',
            header: 'Allele symbol',
            width: 180,
            readOnly: true,
            sortable: false
        }
        ],

        'crispr_common': [
        {
            xtype: 'simpledatecolumn',
            dataIndex: 'mi_date',
            header: 'MI Date',
            width: 90
        }
        ],

        'ES Cell Transfer Details': [
        {
            dataIndex: 'blast_strain_name',
            header: 'Blast Strain',
            sortable: false,
            renderer: 'safeTextRenderer',
            width: 150,
            editor: {
                xtype: 'simplecombo',
                store: Ext.Array.merge([''], window.MI_ATTEMPT_STRAIN_OPTIONS),
                storeOptionsAreSpecial: true,
                listConfig: {
                    minWidth: 160
                }
            }
        },
        {
            dataIndex: 'total_blasts_injected',
            header: 'Total Blasts Injected',
            width: 110,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'total_transferred',
            header: 'Total Transferred',
            width: 100,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_surrogates_receiving',
            header: '# Surrogates Receiving',
            width: 130,
            editor: 'simplenumberfield'
        }
        ],

        'ES Cell Litter Details': [
        {
            dataIndex: 'total_pups_born',
            header: 'Total Pups Born',
            width: 90,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'total_female_chimeras',
            header: 'Total Female Chimeras',
            width: 125,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'total_male_chimeras',
            header: 'Total Male Chimeras',
            width: 110,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'total_chimeras',
            header: 'Total Chimeras',
            width: 90,
            readOnly: true
        },
        {
            dataIndex: 'number_of_males_with_100_percent_chimerism',
            header: '100% Male Chimerism Levels',
            width: 155,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_males_with_80_to_99_percent_chimerism',
            header: '99-80% Male Chimerism Levels',
            width: 165,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_males_with_40_to_79_percent_chimerism',
            header: '79-40% Male Chimerism Levels',
            width: 170,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_males_with_0_to_39_percent_chimerism',
            header: '39-0% Male Chimerism Levels',
            width: 165,
            editor: 'simplenumberfield'
        }
        ],

        'ES Cell Chimera Mating Details': [
        {
            dataIndex: 'test_cross_strain_name',
            header: 'Test Cross Strain',
            readOnly: true,
            sortable: false,
            renderer: 'safeTextRenderer',
            width: 160,
            editor: {
                xtype: 'simplecombo',
                store: Ext.Array.merge([''], window.MI_ATTEMPT_STRAIN_OPTIONS),
                storeOptionsAreSpecial: true,
                listConfig: {
                    minWidth: 160
                }
            }
        },
        {
            dataIndex: 'colony_background_strain_name',
            header: 'Colony Background Strain',
            readOnly: true,
            sortable: false,
            renderer: 'safeTextRenderer',
            width: 160,
            editor: {
                xtype: 'simplecombo',
                store: Ext.Array.merge([''], window.MI_ATTEMPT_STRAIN_OPTIONS),
                storeOptionsAreSpecial: true,
                listConfig: {
                    minWidth: 160
                }
            }
        },
        {
            xtype: 'simpledatecolumn',
            dataIndex: 'date_chimeras_mated',
            width: 120,
            header: 'Date Chimeras Mated'
        },
        {
            dataIndex: 'number_of_chimera_matings_attempted',
            header: '# Chimera Mating Attempted',
            width: 160,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_chimera_matings_successful',
            header: '# Chimera Matings Successful',
            width: 160,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_chimeras_with_glt_from_cct',
            header: '# Chimeras with Germline Transmission from CCT',
            width: 255,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_chimeras_with_glt_from_genotyping',
            header: 'No. Chimeras with Germline Transmission from Genotyping',
            width: 300,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_chimeras_with_0_to_9_percent_glt',
            header: '# Chimeras with 0-9% GLT',
            width: 145,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_chimeras_with_10_to_49_percent_glt',
            header: '# Chimeras with 10-49% GLT',
            width: 155,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_chimeras_with_50_to_99_percent_glt',
            header: 'No. Chimeras with 50-99% GLT',
            width: 165,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_chimeras_with_100_percent_glt',
            header: 'No. Chimeras with 100% GLT',
            width: 160,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'total_f1_mice_from_matings',
            header: 'Total F1 Mice from Matings',
            width: 145,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_cct_offspring',
            header: '# Coat Colour Transmission Offspring',
            width: 200,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_het_offspring',
            header: '# Het Offspring',
            width: 90,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'number_of_live_glt_offspring',
            header: '# Live GLT Offspring',
            width: 115,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'mouse_allele_type',
            header: 'Mouse Allele Type',
            editor: {
                xtype: 'simplecombo',
                store: window.MI_ATTEMPT_MOUSE_ALLELE_TYPE_OPTIONS,
                listConfig: {
                    minWidth: 300
                }
            }
        }
        ],

        'ES Cell QC Details': [
        {
            dataIndex: 'qc_southern_blot_result',
            header: 'Southern Blot',
            sortable: false,
            width: 85,
            editor: 'qccombo'
        },
        {
            dataIndex: 'qc_five_prime_lr_pcr_result',
            header: 'Five Prime LR PCR',
            sortable: false,
            width: 110,
            editor: 'qccombo'
        },
        {
            dataIndex: 'qc_five_prime_cassette_integrity_result',
            header: 'Five Prime Cassette Integrity',
            sortable: false,
            width: 110,
            editor: 'qccombo'
        },
        {
            dataIndex: 'qc_tv_backbone_assay_result',
            header: 'TV Backbone Assay',
            sortable: false,
            width: 110,
            editor: 'qccombo'
        },
        {
            dataIndex: 'qc_neo_count_qpcr_result',
            header: 'Neo Count QPCR',
            sortable: false,
            width: 105,
            editor: 'qccombo'
        },
        {
            dataIndex: 'qc_lacz_count_qpcr_result',
            header: 'Lacz Count QPCR',
            sortable: false,
            width: 105,
            editor: 'qccombo'
        },
        {
            dataIndex: 'qc_neo_sr_pcr_result',
            header: 'Neo SR PCR',
            sortable: false,
            width: 75,
            editor: 'qccombo'
        },
        {
            dataIndex: 'qc_loa_qpcr_result',
            header: 'LOA QPCR',
            sortable: false,
            width: 70,
            editor: 'qccombo'
        },
        {
            dataIndex: 'qc_homozygous_loa_sr_pcr_result',
            header: 'Homozygous LOA SR PCR',
            sortable: false,
            width: 150,
            editor: 'qccombo'
        },
        {
            dataIndex: 'qc_lacz_sr_pcr_result',
            header: 'LacZ SR PCR',
            sortable: false,
            width: 80,
            editor: 'qccombo'
        },
        {
            dataIndex: 'qc_mutant_specific_sr_pcr_result',
            header: 'Mutant Specific SR PCR',
            sortable: false,
            width: 130,
            editor: 'qccombo'
        },
        {
            dataIndex: 'qc_loxp_confirmation_result',
            header: 'LoxP Confirmation',
            sortable: false,
            width: 100,
            editor: 'qccombo'
        },
        {
            dataIndex: 'qc_three_prime_lr_pcr_result',
            header: 'Three Prime LR PCR',
            sortable: false,
            width: 115,
            editor: 'qccombo'
        },
        {
            dataIndex: 'qc_critical_region_qpcr_result',
            header: 'Critical Region QPCR',
            sortable: false,
            width: 115,
            editor: 'qccombo'
        },
        {
            dataIndex: 'qc_loxp_srpcr_result',
            header: 'Loxp SRPCR',
            sortable: false,
            width: 80,
            editor: 'qccombo'
        },
        {
            dataIndex: 'qc_loxp_srpcr_and_sequencing_result',
            header: 'Loxp SRPRC and Sequencing',
            sortable: false,
            width: 155,
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
        },
        {
            dataIndex: 'is_released_from_genotyping',
            header: 'Released From Genotyping',
            xtype: 'boolgridcolumn'
        }
        ],

        'Crispr Transfer Details': [
        {
            dataIndex: 'crsp_total_embryos_injected',
            header: '# Embryos Injected',
            width: 110,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'crsp_total_embryos_survived',
            header: '# Embryos Survived',
            width: 115,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'crsp_total_transfered',
            header: '# Transferred',
            width: 90,
            editor: 'simplenumberfield'
        }
        ],

        'Crispr Founder Details': [
        {
            dataIndex: 'crsp_no_founder_pups',
            header: '# No Pups',
            width: 65,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'founder_pcr_num_assays',
            header: '# PCR Assays',
            width: 80,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'founder_pcr_num_positive_results',
            header: '# PCR +ve Results',
            width: 105,
            editor: 'simplenumberfield'
        },
                {
            dataIndex: 'founder_surveyor_num_assays',
            header: '# Surveyor Assays',
            width: 105,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'founder_surveyor_num_positive_results',
            header: '# Surveyor +ve Results',
            width: 130,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'founder_t7en1_num_assays',
            header: '# T7EN1 Assays',
            width: 95,
            editor: 'simplenumberfield'
        },
                {
            dataIndex: 'founder_t7en1_num_positive_results',
            header: '# T7EN1 +ve Assays',
            width: 115,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'founder_loa_num_assays',
            header: '# LOA Assays',
            width: 90,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'founder_loa_num_positive_results',
            header: '# LOA +ve Results',
            width: 105,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'crsp_total_num_mutant_founders',
            header: '# Mutants',
            width: 60,
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'crsp_num_founders_selected_for_breading',
            header: '# For Breeding',
            width: 90,
            editor: 'simplenumberfield'
        }
        ],

        'Crispr F1 Details': [
        ],

        'Crispr QC Details': [
        ]
    },

    additionalViewColumns: {
        'Summary': [
        'emma_status'
        ]
    }
// END COLUMN DEFINITION - ALWAYS keep at bottom of file for easier organization

});

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
                    console.log(genotype_confirmed_colony_names);
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
Ext.define('Imits.widget.MiPlansGridCommon', {
    extend: 'Imits.widget.Grid',

    requires: [
    'Imits.model.MiPlan',
    'Imits.widget.grid.RansackFiltersFeature'
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
        dataIndex: 'mutagenesis_via_crispr_cas9',
        header: 'Mutagenesis via CrispR Cas9',
        xtype: 'boolgridcolumn',
        width: 150,
        readOnly: true
    },
    {
        dataIndex: 'phenotype_only',
        header: 'Phenotype Only',
        xtype: 'boolgridcolumn',
        width: 90,
        readOnly: true
    },
    {
        dataIndex: 'is_conditional_allele',
        header: 'Knockout First tm1a',
        xtype: 'boolgridcolumn',
        width: 110,
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
        width: 80,
        readOnly: true
    },
    {
        dataIndex: 'is_cre_bac_allele',
        header: 'Cre BAC',
        xtype: 'boolgridcolumn',
        width: 60,
        readOnly: true
    },
    {
        dataIndex: 'is_bespoke_allele',
        header: 'Bespoke',
        xtype: 'boolgridcolumn',
        width: 60,
        readOnly: true,
        hidden: true
    },
    {
        dataIndex: 'conditional_tm1c',
        header: 'Conditional tm1c',
        xtype: 'boolgridcolumn',
        width: 90,
        readOnly: true
    },
    {
        dataIndex: 'point_mutation',
        header: 'Point Mutation',
        xtype: 'boolgridcolumn',
        width: 80,
        readOnly: true
    },
    {
        dataIndex: 'conditional_point_mutation',
        header: 'Conditional Point Mutation',
        xtype: 'boolgridcolumn',
        width: 140,
        readOnly: true
    },
    {
        dataIndex: 'ignore_available_mice',
        header: 'Ignore Available Mice',
        xtype: 'boolgridcolumn',
        width: 120,
        readOnly: true
    }
]
});

Ext.define('Imits.widget.MiPlansGrid', {
    extend: 'Imits.widget.MiPlansGridCommon',

    // extends the MiPlanColumns in MiPlanGridCommon. These column should be independent from the MiPlanGridGeneral (read only grid). columns common to read only grid and editable grid should be added to MiPlanGridCommon.
    additionalColumns: [{'position': 1 ,
                         'data': { header: 'Edit In Form',
                                   dataIndex: 'edit_link',
                                   renderer: function(value, metaData, record) {
                                       var id = record.getId();
                                       return Ext.String.format('<a href="{0}/mi_plans/{1}">Edit in Form</a>', window.basePath, id);
                                   },
                                   sortable: false
                                  }
                         }
    ],

    initComponent: function() {
        grid = this;
        // Adds additional columns
        Ext.Array.each(grid.additionalColumns, function(column) {
            grid.addColumn(column['data'], column['position']);
        });
        this.callParent();
    }
})
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
Ext.define('Imits.widget.Window', {
    extend: 'Ext.window.Window',

    plain: true,

    showLoadMask: function() {
        this.loadMask = new Ext.LoadMask(this.getComponent(0).getEl());
        this.loadMask.show();
    },

    hideLoadMask: function() {
        this.loadMask.hide();
    }
});

Ext.define('Imits.widget.NotificationPane', {
    extend: 'Imits.widget.Window',

    requires: [
    'Imits.model.Notification'
    ],

    title: 'View Notification',
    resizable: true,
    layout: 'fit',
    closeAction: 'hide',
    cls: 'notification view',

    constructor: function (config) {
        //if(Ext.isIE7 || Ext.isIE8) {
        //    config.width = 400;
        //}
        return this.callParent([config]);
    },

    initComponent: function () {
        var editor = this;
        this.callParent();

        this.form = Ext.create('Ext.form.Panel', {
            ui: 'plain',
            margin: '0 0 10 0',
            width: 600,

            layout: 'anchor',
            defaults: {
                anchor: '100%',
                labelWidth: 150,
                labelAlign: 'right',
                labelPad: 10
            },

            items: [
            {
                id: 'welcome_email',
                xtype: 'textarea',
                fieldLabel: 'Welcome email',
                name: 'welcome_email',
                height: 230,
                readOnly: true
            },
            {
                id: 'last_email',
                xtype: 'textarea',
                fieldLabel: 'Last email',
                name: 'last_email',
                height: 230,
                readOnly: true
            }
            ],

            buttons: [
                {
                    text: 'Cancel',
                    handler: function () {
                        editor.hide();
                    }
                }
            ]
        });

        
        var panelHeight = 520;
        
        this.add(Ext.create('Ext.panel.Panel', {
            height: panelHeight,
            ui: 'plain',
            layout: {
                type: 'vbox',
                align: 'stretchmax'
            },
            padding: 5,
            items: [
                editor.form
            ]
        }));

        this.fields = this.form.items.keys;
    },
    load: function (notificationId) {
        var editor = this;

        Imits.model.Notification.load(notificationId, {
            success: function (notification) {
                editor.notification = notification;
                Ext.each(editor.fields, function (attr) {
                    var component = editor.form.getComponent(attr);
                    if(component) {
                        component.setValue(editor.notification.get(attr));
                    }
                });
                editor.show();
            }
        });
    },
});

Ext.define('Imits.widget.NotificationsGrid', {
    extend: 'Imits.widget.Grid',

    requires: [
      'Imits.model.Notification',
      'Imits.widget.NotificationPane',
      'Imits.widget.grid.RansackFiltersFeature',
      'Imits.Util'
    ],

    title: 'Notifications',
    iconCls: 'icon-grid',
    columnLines: true,

    store: {
        model: 'Imits.model.Notification',
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

    createNotification: function() {
        var self = this;
        var emailAddress = self.emailField.getSubmitValue();
        var geneField = self.geneField.getSubmitValue();

        if(!emailAddress || emailAddress && !emailAddress.length) {
            alert("You must enter a Email Address.");
            return
        }

        if(!geneField || geneField && !geneField.length) {
            alert("You must enter a gene marker symbol.");
            return
        }

        self.setLoading(true);

        var notificationRecord = Ext.create('Imits.model.Notification', {
            'contact_email' : emailAddress,
            'gene_marker_symbol' : geneField
        });

        notificationRecord.save({
            callback: function() {
                self.reloadStore();
                self.setLoading(false);

                self.geneField.setValue()
                self.emailField.setValue()
            }
        })
    },

    initComponent: function () {
      var self = this;

      self.callParent();

      self.addDocked(Ext.create('Ext.toolbar.Paging', {
          store: self.getStore(),
          dock: 'bottom',
          displayInfo: true
      }));

      self.notificationPane = Ext.create('Imits.widget.NotificationPane', {
          listeners: {
              'hide': {
                  fn: function () {
                      self.setLoading(false);
                  }
              }
          }
      });

      self.getView().on('cellmousedown',function(view, cell, cellIdx, record, row, rowIdx, eOpts){
        var id = record.data['id'];
        self.setLoading("Loading notification....");
        self.notificationPane.load(id);
      });

      self.geneField = Ext.create('Ext.form.field.ComboBox', {
        displayField: 'gene_name',
        store: window.GENE_OPTIONS,
        fieldLabel: 'Gene of interest',
        labelAlign: 'right',
        labelWidth: 100,
        queryMode: 'local',
        typeAhead: true
      });

      self.emailField = Ext.create('Ext.form.field.Text', {
        fieldLabel: 'Email address',
        name: 'email',
        labelWidth: 80,
        width:250,
        labelAlign: 'right'
      })

      self.addDocked(Ext.create('Ext.toolbar.Toolbar', {
          dock: 'top',
          items: [
            self.geneField,
            self.emailField,
            '  ',
            {
                id: 'register_interest_button',
                text: 'Register interest',
                cls:'x-btn-text-icon',
                iconCls: 'icon-add',
                grid: self,
                handler: function() {
                    self.createNotification();
                }
            }
         ]
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
      dataIndex: "gene_id",
      header: "Gene ID",
      hidden: true
    },
    {
      dataIndex: "gene_marker_symbol",
      header: "Gene",
      filter: {
        type: 'string'
      }
    },
    {
      dataIndex: "contact_id",
      header: "Contact ID",
      hidden: true
    },
    {
      dataIndex: "contact_email",
      header: "Contact",
      width:180,
      filter: {
        type: 'string'
      }
    },
    {
      dataIndex: "last_email_sent",
      xtype: 'datecolumn',
      format: "Y-m-d H:i:s",
      header: "Last email sent",
      width:130
    },
    {
      dataIndex: "welcome_email_sent",
      xtype: 'datecolumn',
      format: "Y-m-d H:i:s",
      header: "Welcome email sent",
      width:130
    },
    {
      dataIndex: "updated_at",
      xtype: 'datecolumn',
      format: "Y-m-d H:i:s",
      header: "Last updated",
      hidden: true,
      width:130
    },
    {
      xtype:'actioncolumn',
      width:21,
      items: [{
          icon: '../images/icons/time_go.png',
          tooltip: 'Resend',
          handler: function(grid, rowIndex, colIndex) {
              var record = grid.getStore().getAt(rowIndex);
              var id = record.data['id'];
              if(confirm("Are you sure you want to resend this notification?")) {

                // Fix for sessions
                Ext.Ajax.request({
                    url: document.location.pathname + '/' + id + '/retry.json',
                    method: 'PUT',
                    params: {
                      'authenticity_token': window.authenticityToken
                    },
                    success: function(response){
                        var text = response.responseText;
                        // process server response here
                    }
                });

              }
          }
      }]
    }
    ]
});

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

Ext.define('Imits.widget.PhenotypeAttemptsGrid', {
    extend: 'Imits.widget.PhenotypeAttemptsGridCommon',

    additionalColumns: [{'position' : 1,
                         'data' : {header: 'Edit In Form',
                                   dataIndex: 'edit_link',
                                   renderer: function(value, metaData, record) {
                                       var miId = record.getId();
                                       return Ext.String.format('<a href="{0}/phenotype_attempts/{1}">Edit in Form</a>', window.basePath, miId);
                                   },
                                   sortable: false
                                   }
                        },
                        {'position': 5,
                         'data': {header: 'Distribution Centres',
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
                            }
                      }
    ],

    initComponent: function () {
        var grid = this;
        Ext.Array.each(grid.additionalColumns, function(column) {
                grid.addColumn(column['data'], column['position']);
        });
        grid.callParent();
    }

});
Ext.define('Imits.widget.PhenotypeAttemptsGridGeneral', {
    extend: 'Imits.widget.PhenotypeAttemptsGridCommon',

    additionalColumns: [{'position' : 1,
                         'data' : {header: 'Show In Form',
                                   dataIndex: 'show_link',
                                   renderer: function(value, metaData, record) {
                                       var miId = record.getId();
                                       return Ext.String.format('<a href="{0}/open/phenotype_attempts/{1}">Show in Form</a>', window.basePath, miId);
                                   },
                                   sortable: false
                                   }
                        },
                        {'position': 5,
                         'data': {header: 'Distribution Centres',
                                  dataIndex: 'distribution_centres_formatted_display',
                                  readOnly: true,
                                  sortable: false,
                                  width: 225,
                                  renderer: function(value, metaData, record){
                                      var paId = record.getId();
                                      var distribution_centres = record.get('distribution_centres_formatted_display');
                                      if (distribution_centres != '') {
                                          return Ext.String.format('<a href="{0}/open/phenotype_attempts/{1}#distribution_centres" target="_blank">{2}</a>', window.basePath, paId, distribution_centres);
                                      } else {
                                          return Ext.String.format('{0}', distribution_centres);
                                      }
                                 }
                            }
                      },
                      {'position' : 2,
                         'data' : {header: 'Phenotyping Summary',
                                   dataIndex: 'phenotyping_summary',
                                   width: 125,
                                   renderer: function(value, metaData, record) {
                                       var mgi_accession_id = record.get('mgi_accession_id');
                                       if (mgi_accession_id != '') {
                                         return Ext.String.format('<a href="https://www.mousephenotype.org/data/genes/{0}">View in IMPC Website</a>', mgi_accession_id);
                                       } else {
                                         return Ext.String.format('{0}', '');
                                       }
                                   },
                                   sortable: false
                                   }
                        }
    ],

    initComponent: function () {
        var grid = this;
        Ext.Array.each(grid.additionalColumns, function(column) {
                grid.addColumn(column['data'], column['position']);
        });
        grid.callParent();
    }

});

Ext.define('Imits.widget.ProductionGoalsGrid', {
    extend: 'Imits.widget.Grid',

    requires: [
        'Imits.model.ProductionGoal',
        'Imits.widget.grid.RansackFiltersFeature',
        'Imits.Util'
    ],

    title: 'Production Goals',
    iconCls: 'icon-grid',
    columnLines: true,

    store: {
        model: 'Imits.model.ProductionGoal',
        autoLoad: true,
        autoSync: true,
        remoteSort: true,
        remoteFilter: true,
      //  onUpdateRecords: function(records, operation, success) {
       //     console.log(records);
        //}
    },

    selType: 'rowmodel',

    features: [
    {
        ftype: 'ransack_filters',
        local: false
    }
    ],

    plugins: [
    Ext.create('Ext.grid.plugin.RowEditing', {
        autoCancel: false,
        clicksToEdit: 1
    })
    ],

    createProductionGoal: function() {
        var self = this;
        var consortiumName = self.consortiumCombo.getSubmitValue();
        var yearValue      = self.yearText.getSubmitValue();
        var monthValue     = self.monthText.getSubmitValue();
        var miValue        = self.miText.getSubmitValue();
        var gcValue        = self.gcText.getSubmitValue();
        var crisprmiValue  = self.miText.getSubmitValue();
        var crisprgcValue  = self.gcText.getSubmitValue();

        if(!consortiumName || consortiumName && !consortiumName.length) {
            alert("You must enter a valid Consortium.");
            return
        }

        if(!yearValue.length || yearValue.length && (yearValue < 2010 || yearValue > 2050)) {
            alert("You must enter a valid year.");
            return;
        }

        if(monthValue.length && (monthValue < 1 || monthValue > 12)) {
            alert("You must enter a valid month.");
            return
        }

        if(!miValue.length || !gcValue) {
            alert("You must enter correct production goal values.")
            return
        }

        self.setLoading(true);

        var productionGoal = Ext.create('Imits.model.ProductionGoal', {
            'consortium_name' : consortiumName,
            'year' : yearValue,
            'month' : monthValue,
            'mi_goal' : miValue,
            'gc_goal' : gcValue,
            'crispr_mi_goal' : crisprmiValue,
            'crispr_gc_goal' : crisprgcValue
        });

        productionGoal.save({
            callback: function() {
                self.reloadStore();
                self.setLoading(false);


                self.consortiumCombo.setValue()
                self.yearText.setValue()
                self.monthText.setValue()
                self.miText.setValue()
                self.gcText.setValue()
            }
        })
    },

    initComponent: function () {
        var self = this;

        self.callParent();

        self.addDocked(Ext.create('Ext.toolbar.Paging', {
            store: self.getStore(),
            dock: 'bottom',
            displayInfo: true
        }));

        // Add the create toolbar.
        self.consortiumCombo = Ext.create('Imits.widget.SimpleCombo', {
            id: 'consortiumCombobox',
            store: window.CONSORTIUM_OPTIONS,
            fieldLabel: 'Consortium',
            labelAlign: 'right',
            labelWidth: 55,
            storeOptionsAreSpecial: true,
            hidden: false
        });

        self.yearText = Ext.create('Ext.form.field.Number', {
            fieldLabel: 'Year',
            name: 'year',
            labelWidth: 30,
            labelAlign: 'right',
            regex: /[1-9-]*/
        });

        //[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]

        self.monthText = Ext.create('Ext.form.field.Number', {
            fieldLabel: 'Month',
            name: 'month',
            labelWidth: 35,
            labelAlign: 'right',
            regex: /[1-9-]*/
        });

        self.miText = Ext.create('Ext.form.field.Number', {
            fieldLabel: 'MI Goal',
            name: 'mi_goal',
            labelWidth: 40,
            labelAlign: 'right',
            regex: /[1-9-]*/
        });

        self.gcText = Ext.create('Ext.form.field.Number', {
            fieldLabel: 'GC Goal',
            name: 'gc_goal',
            labelWidth: 40,
            labelAlign: 'right',
            regex: /[1-9-]*/
        });

        self.crisprmiText = Ext.create('Ext.form.field.Number', {
            fieldLabel: 'Crispr MI Goal',
            name: 'crispr_mi_goal',
            labelWidth: 40,
            labelAlign: 'right',
            regex: /[1-9-]*/
        });

        self.crisprgcText = Ext.create('Ext.form.field.Number', {
            fieldLabel: 'Crispr GC Goal',
            name: 'crispr_gc_goal',
            labelWidth: 40,
            labelAlign: 'right',
            regex: /[1-9-]*/
        });
        self.addDocked(Ext.create('Ext.toolbar.Toolbar', {
            dock: 'top',
            items: [
            self.consortiumCombo,
            self.yearText,
            self.monthText,
            self.miText,
            self.gcText,
            self.crisprmiText,
            self.crisprgcText,
            '  ',
            {
                id: 'register_interest_button',
                text: 'Create goals',
                cls:'x-btn-text-icon',
                iconCls: 'icon-add',
                grid: self,
                handler: function() {
                    self.createProductionGoal();
                }
            }
           ]
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
            dataIndex: 'consortium_name',
            header: 'Consortium',
            editor: {
                xtype: 'simplecombo',
                store: Ext.Array.merge([''], window.CONSORTIUM_OPTIONS),
                storeOptionsAreSpecial: true,
                listConfig: {
                    minWidth: 200
                }
            },
            filter: {
                type: 'list',
                options: window.CONSORTIUM_OPTIONS
            }
        },
        {
            dataIndex: 'year',
            header: 'Year',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'month',
            header: 'Month',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'mi_goal',
            header: 'MI Goal',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'gc_goal',
            header: 'GC Goal',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'crispr_mi_goal',
            header: 'Crispr MI Goal',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'crispr_gc_goal',
            header: 'Crispr GC Goal',
            editor: 'simplenumberfield'
        },
        {
            xtype:'actioncolumn',
            width:21,
            items: [{
                icon: 'images/icons/delete.png',
                tooltip: 'Delete',
                handler: function(grid, rowIndex, colIndex) {
                    var rec = grid.getStore().getAt(rowIndex);
                    if(confirm("Remove production goal?"))
                        grid.getStore().removeAt(rowIndex)
                }
            }]
        },
        {
            header: 'History',
            dataIndex: 'edit_link',
            renderer: function(value, metaData, record) {
                var pgId = record.getId();
                return Ext.String.format('<a href="{0}/production_goals/{1}/history">View history</a>', window.basePath, pgId);
            },
            sortable: false
        }
    ]
});

Ext.define('Imits.widget.SolrUpdateQueueItemsGrid', {
    extend: 'Imits.widget.Grid',

    requires: [
    'Imits.widget.grid.RansackFiltersFeature',
    'Imits.model.SolrUpdateQueueItem',
    'Imits.Util'
    ],

    title: 'Solr Update Queue Items',
    iconCls: 'icon-grid',
    columnLines: true,

    store: {
        model: 'Imits.model.SolrUpdateQueueItem',
        autoLoad: true,
        remoteSort: true,
        remoteFilter: true,
        pageSize: 200
    },

    features: [
    {
        ftype: 'ransack_filters',
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
        width: 60
    },
    {
        dataIndex: 'reference',
        header: 'Reference',
        readOnly: true,
        flex: 1,
        renderer: function (value, metaData, record) {
            var ref = record.get('reference');

            if(ref.type == "allele") {
              var editUrl = Ext.String.format('{0}/{1}s/{2}', document.location.pathname.replace(/solr_update\/queue\/items/, "targ_rep"), ref.type, ref.id);
            } else {
              var editUrl = Ext.String.format('{0}/{1}s/{2}', window.basePath, ref.type, ref.id);
            }

						var historyUrl =  editUrl + '/history';

            return Ext.String.format('<a href="{0}">{1} / {2}</a> (<a href="{3}">audit history</a>)', editUrl, ref.type, ref.id, historyUrl);
        }
    },
    {
        dataIndex: 'action',
        header: 'Action',
        readOnly: true,
        width: 60,
        filter: {
            type: 'list',
            options: ['update', 'delete']
        }
    },
    {
        dataIndex: 'created_at',
        xtype: 'datecolumn',
        format: 'd-m-Y H:i:s',
        header: 'Created At',
        readOnly: true,
        width: 125
    },
    {
        header: '',
        xtype: 'actioncolumn',
        width: 48,
        items: [
        {
            icon: window.basePath + '/images/icons/resultset_next.png',
            tooltip: 'Run now',
            handler: function (grid, rowIndex, colIndex) {
                var item = grid.getStore().getAt(rowIndex);
                var itemId = item.get('id');
                Ext.Msg.confirm('Run item?',
                    'Run item ' + itemId + '?',
                    function (buttonName) {
                        if (buttonName === 'yes') {
                            grid.setLoading('Running item ' + itemId);

                            Ext.Ajax.request({
                                method: 'POST',
                                params: {
                                    'authenticity_token': window.authenticityToken
                                    },
                                url: window.basePath + '/solr_update/queue/items/' + itemId + '/run.json',
                                success: function () {
                                    grid.getStore().remove(item);
                                },
                                failure: function (response) {
                                    Imits.Util.handleErrorResponse(response);
                                },
                                callback: function () {
                                    grid.setLoading(false);
                                }
                            });
                        }
                    });
            }
        },
        {
            icon: window.basePath + '/images/icons/cancel.png',
            tooltip: 'Delete',
            handler: function (grid, rowIndex, colIndex) {
                var item = grid.getStore().getAt(rowIndex);
                Ext.Msg.confirm('Delete item?',
                    'Delete item ' + item.get('id') + '?',
                    function (buttonName) {
                        if (buttonName === 'yes') {
                            grid.setLoading('Deleting item ' + item.get('id'));
                            item.destroy({
                                success: function () {
                                    grid.getStore().remove(item);
                                },

                                callback: function () {
                                    grid.setLoading(false);
                                }

                            });
                        }
                    });
            }
        }
        ]
    },
    {
        header: '',
        width: 80,
        renderer: function (value, metaData, record) {
            var ref = record.get('reference');
            return Ext.String.format('<a href="{0}/search?q=type:{1}+id:{2}&indent=on">{3}</a>',
                window.SOLR_ALLELE_URL, ref.type, ref.id, 'SOLR view');
        }
    }
    ]
});

Ext.define('Imits.widget.StrainsGrid', {
    extend: 'Imits.widget.Grid',

    requires: [
      'Imits.model.Strain',
      'Imits.widget.grid.RansackFiltersFeature',
      'Imits.Util'
    ],

    title: 'Strains',
    iconCls: 'icon-grid',
    columnLines: true,

    store: {
        model: 'Imits.model.Strain',
        autoLoad: true,
        autoSync: true,
        remoteSort: true,
        remoteFilter: true,
        pageSize: 25
    },

    selType: 'rowmodel',

    features: [
    {
        ftype: 'ransack_filters',
        local: false
    }
    ],

    plugins: [
      Ext.create('Ext.grid.plugin.RowEditing', {
          autoCancel: false,
          clicksToEdit: 1
      })
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
      dataIndex: 'name',
      header: 'ID',
      width:300,
      filter: {
        type: 'string'
      },
      editor: 'textfield'
    },
    {
      dataIndex: 'mgi_strain_accession_id',
      header: 'MGI Accession Id',
      width:300,
      filter: {
        type: 'string'
      },
      editor: 'textfield'
    },
    {
      dataIndex: 'mgi_strain_name',
      header: 'MGI Strain Name',
      width:300,
      filter: {
        type: 'string'
      },
      editor: 'textfield'
    },
    {
      xtype:'actioncolumn',
      width:21,
      items: [{
        icon: 'images/icons/delete.png',
        tooltip: 'Delete',
        handler: function(grid, rowIndex, colIndex) {
          var record = grid.getStore().getAt(rowIndex);

          if(confirm("Remove strain?"))
            grid.getStore().removeAt(rowIndex)

        }
      }]
    }
    ]
});

Ext.define('Imits.widget.TrackingGoalsConsortiaBreakdownGrid', {
    extend: 'Imits.widget.Grid',

    requires: [
        'Imits.model.TrackingGoal',
        'Imits.widget.grid.RansackFiltersFeature',
        'Imits.Util'
    ],

    title: 'Tracking Goals',
    iconCls: 'icon-grid',
    columnLines: true,

    store: {
        model: 'Imits.model.TrackingGoal',
        autoLoad: true,
        autoSync: true,
        remoteSort: true,
        remoteFilter: true,
      //  onUpdateRecords: function(records, operation, success) {
       //     console.log(records);
        //}
    },

    selType: 'rowmodel',

    features: [
    {
        ftype: 'ransack_filters',
        local: false
    }
    ],

    plugins: [
    Ext.create('Ext.grid.plugin.RowEditing', {
        autoCancel: false,
        clicksToEdit: 1
    })
    ],

    createTrackingGoal: function() {
        var self = this;
        var consortiumName = self.consortiumCombo.getSubmitValue();
        var centreName     = self.centreCombo.getSubmitValue();
        var yearValue      = self.yearText.getSubmitValue();
        var monthValue     = self.monthText.getSubmitValue();
        var goalValue      = self.goalText.getSubmitValue();
        var typeValue      = self.typeText.getSubmitValue();

        if(!consortiumName || consortiumName && !consortiumName.length) {
            alert("You must enter a valid Consortium.");
            return
        }

        if(!centreName || centreName && !centreName.length) {
            alert("You must enter a valid Centre.");
            return
        }

        //if(!yearValue.length || yearValue.length && (yearValue < 2010 || yearValue > 2050)) {
        //    alert("You must enter a valid year.");
        //    return;
        //}

        //if(monthValue.length && (monthValue < 1 || monthValue > 12)) {
        //    alert("You must enter a valid month.");
        //    return
        //}

        if(!goalValue.length || !typeValue) {
            alert("You must enter correct tracking goal values.")
            return
        }

        self.setLoading(true);

        var trackingGoal = Ext.create('Imits.model.TrackingGoal', {
            'consortium_name' : consortiumName,
            'production_centre_name' : centreName,
            'year'      : yearValue,
            'month'     : monthValue,
            'goal'      : goalValue,
            'goal_type' : typeValue
        });

        trackingGoal.save({
            callback: function() {
                self.reloadStore();
                self.setLoading(false);

                self.consortiumCombo.setValue()
                self.centreCombo.setValue()
                self.yearText.setValue()
                self.monthText.setValue()
                self.goalText.setValue()
                self.typeText.setValue()
            }
        })
    },

    initComponent: function () {
        var self = this;

        self.callParent();

        self.addDocked(Ext.create('Ext.toolbar.Paging', {
            store: self.getStore(),
            dock: 'bottom',
            displayInfo: true
        }));

        // Add the create toolbar.
        self.consortiumCombo = Ext.create('Imits.widget.SimpleCombo', {
            id: 'consortiumCombobox',
            store: window.CONSORTIUM_OPTIONS,
            fieldLabel: 'Consortium',
            labelAlign: 'right',
            labelWidth: 65,
            storeOptionsAreSpecial: true,
            hidden: false
        });

        self.centreCombo = Ext.create('Imits.widget.SimpleCombo', {
            id: 'centreCombobox',
            store: window.CENTRE_OPTIONS,
            fieldLabel: 'Production centre',
            labelAlign: 'right',
            labelWidth: 65,
            storeOptionsAreSpecial: true,
            hidden: false
        });

        self.yearText = Ext.create('Ext.form.field.Number', {
            fieldLabel: 'Year',
            name: 'year',
            labelWidth: 50,
            labelAlign: 'right',
            regex: /[1-9-]*/
        });

        //[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]

        self.monthText = Ext.create('Ext.form.field.Number', {
            fieldLabel: 'Month',
            name: 'month',
            labelWidth: 50,
            labelAlign: 'right',
            regex: /[1-9-]*/
        });

        self.goalText = Ext.create('Ext.form.field.Number', {
            fieldLabel: 'Goal',
            name: 'goal',
            labelWidth: 50,
            labelAlign: 'right',
            regex: /[1-9-]*/
        });

        self.typeText = Ext.create('Imits.widget.SimpleCombo', {
            fieldLabel: 'Goal type',
            store: window.GOAL_TYPES,
            storeOptionsAreSpecial: true,
            name: 'goal_type',
            labelWidth: 50,
            labelAlign: 'right',
            width: 250,
            hidden: false
        });

        self.addDocked(Ext.create('Ext.toolbar.Toolbar', {
            dock: 'top',
            items: [
            self.consortiumCombo,
            self.centreCombo,
            self.yearText,
            self.monthText,
            self.goalText,
            self.typeText,
            '  ',
            {
                id: 'register_interest_button',
                text: 'Create tracking goal',
                cls:'x-btn-text-icon',
                iconCls: 'icon-add',
                grid: self,
                handler: function() {
                    self.createTrackingGoal();
                }
            }
           ]
        }));

        self.addListener('afterrender', function () {
            self.filters.createFilters();
        });
    },

    columns: [
        {
            dataIndex: 'id',
            header: 'ID',
            readOnly: true,
            hidden: true
        },
        {
            dataIndex: 'consortium_name',
            header: 'Consortium',
            editor: {
                xtype: 'simplecombo',
                store: Ext.Array.merge([''], window.CONSORTIUM_OPTIONS),
                storeOptionsAreSpecial: true,
                listConfig: {
                    minWidth: 200
                }
            },
            sortable: false,
            filter: {
                type: 'list',
                options: window.CONSORTIUM_OPTIONS
            }
        },
        {
            dataIndex: 'production_centre_name',
            header: 'Production centre',
            editor: {
                xtype: 'simplecombo',
                store: Ext.Array.merge([''], window.CENTRE_OPTIONS),
                storeOptionsAreSpecial: true,
                listConfig: {
                    minWidth: 200
                }
            },
            sortable: false,
            filter: {
                type: 'list',
                options: window.CENTRE_OPTIONS
            }
        },
        {
            dataIndex: 'year',
            header: 'Year',
            editor: 'simplenumberfield',
            sortable: false
        },
        {
            dataIndex: 'month',
            header: 'Month',
            editor: 'simplenumberfield',
            sortable: false
        },
        {
            dataIndex: 'goal',
            header: 'Goal',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'goal_type',
            header: 'Goal type',
            editor: {
                xtype: 'simplecombo',
                store: Ext.Array.merge([''], window.GOAL_TYPES),
                storeOptionsAreSpecial: true,
                listConfig: {
                    minWidth: 200
                }
            },
            filter: {
                type: 'list',
                options: window.GOAL_TYPES
            }
        },
        {
            xtype:'actioncolumn',
            width:21,
            items: [{
                icon: 'images/icons/delete.png',
                tooltip: 'Delete',
                handler: function(grid, rowIndex, colIndex) {
                    var rec = grid.getStore().getAt(rowIndex);
                    if(confirm("Remove tracking goal?"))
                        grid.getStore().removeAt(rowIndex)
                }
            }]
        },
        {
            header: 'History',
            dataIndex: 'edit_link',
            renderer: function(value, metaData, record) {
                var pgId = record.getId();
                return Ext.String.format('<a href="{0}/tracking_goals/{1}/history">View history</a>', window.basePath, pgId);
            },
            sortable: false
        },
        {
            dataIndex: 'no_consortium_id',
            header: 'No Consortium',
            filter: {
                type: 'list',
                options: ['0','1'],
                value:'0',
                active: true
            },
           hidden: true,
           sortable: false
        }
    ]
});

Ext.define('Imits.widget.TrackingGoalsGrid', {
    extend: 'Imits.widget.Grid',

    requires: [
        'Imits.model.TrackingGoal',
        'Imits.widget.grid.RansackFiltersFeature',
        'Imits.Util'
    ],

    title: 'Tracking Goals',
    iconCls: 'icon-grid',
    columnLines: true,

    store: {
        model: 'Imits.model.TrackingGoal',
        autoLoad: true,
        autoSync: true,
        remoteSort: true,
        remoteFilter: true,
      //  onUpdateRecords: function(records, operation, success) {
       //     console.log(records);
        //}
    },

    selType: 'rowmodel',

    features: [
    {
        ftype: 'ransack_filters',
        local: false
    }
    ],

    plugins: [
    Ext.create('Ext.grid.plugin.RowEditing', {
        autoCancel: false,
        clicksToEdit: 1
    })
    ],

    createTrackingGoal: function() {
        var self = this;
        var centreName     = self.centreCombo.getSubmitValue();
        var yearValue      = self.yearText.getSubmitValue();
        var monthValue     = self.monthText.getSubmitValue();
        var goalValue      = self.goalText.getSubmitValue();
        var crisprgoalValue = self.crisprgoalText.getSubmitValue();
        var typeValue      = self.typeText.getSubmitValue();

        if(!centreName || centreName && !centreName.length) {
            alert("You must enter a valid Centre.");
            return
        }

        //if(!yearValue.length || yearValue.length && (yearValue < 2010 || yearValue > 2050)) {
        //    alert("You must enter a valid year.");
        //    return;
        //}

        //if(monthValue.length && (monthValue < 1 || monthValue > 12)) {
        //    alert("You must enter a valid month.");
        //    return
        //}

        if(!goalValue.length || !typeValue) {
            alert("You must enter correct tracking goal values.")
            return
        }

        self.setLoading(true);

        var trackingGoal = Ext.create('Imits.model.TrackingGoal', {
            'production_centre_name' : centreName,
            'year'      : yearValue,
            'month'     : monthValue,
            'goal'      : goalValue,
            'crispr_goal' : crisprgoalValue,
            'goal_type' : typeValue
        });

        trackingGoal.save({
            callback: function() {
                self.reloadStore();
                self.setLoading(false);


                self.centreCombo.setValue()
                self.yearText.setValue()
                self.monthText.setValue()
                self.goalText.setValue()
                self.crisprgoalText.setValue()
                self.typeText.setValue()
            }
        })
    },

    initComponent: function () {
        var self = this;

        self.callParent();

        self.addDocked(Ext.create('Ext.toolbar.Paging', {
            store: self.getStore(),
            dock: 'bottom',
            displayInfo: true
        }));

        // Add the create toolbar.
        self.centreCombo = Ext.create('Imits.widget.SimpleCombo', {
            id: 'centreCombobox',
            store: window.CENTRE_OPTIONS,
            fieldLabel: 'Production centre',
            labelAlign: 'right',
            labelWidth: 65,
            storeOptionsAreSpecial: true,
            hidden: false
        });

        self.yearText = Ext.create('Ext.form.field.Number', {
            fieldLabel: 'Year',
            name: 'year',
            labelWidth: 50,
            labelAlign: 'right',
            regex: /[1-9-]*/
        });

        //[1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12]

        self.monthText = Ext.create('Ext.form.field.Number', {
            fieldLabel: 'Month',
            name: 'month',
            labelWidth: 50,
            labelAlign: 'right',
            regex: /[1-9-]*/
        });

        self.goalText = Ext.create('Ext.form.field.Number', {
            fieldLabel: 'Goal',
            name: 'goal',
            labelWidth: 50,
            labelAlign: 'right',
            regex: /[1-9-]*/
        });

        self.crisprgoalText = Ext.create('Ext.form.field.Number', {
            fieldLabel: 'Crispr Goal',
            name: 'crispr_goal',
            labelWidth: 50,
            labelAlign: 'right',
            regex: /[1-9-]*/
        });

        self.typeText = Ext.create('Imits.widget.SimpleCombo', {
            fieldLabel: 'Goal type',
            store: window.GOAL_TYPES,
            storeOptionsAreSpecial: true,
            name: 'goal_type',
            labelWidth: 50,
            labelAlign: 'right',
            width: 250,
            hidden: false
        });

        self.addDocked(Ext.create('Ext.toolbar.Toolbar', {
            dock: 'top',
            items: [
            self.centreCombo,
            self.yearText,
            self.monthText,
            self.goalText,
            self.crisprgoalText,
            self.typeText,
            '  ',
            {
                id: 'register_interest_button',
                text: 'Create tracking goal',
                cls:'x-btn-text-icon',
                iconCls: 'icon-add',
                grid: self,
                handler: function() {
                    self.createTrackingGoal();
                }
            }
           ]
        }));

        self.addListener('afterrender', function () {
            self.filters.createFilters();
        });
    },

    columns: [
        {
            dataIndex: 'id',
            header: 'ID',
            readOnly: true,
            hidden: true
        },
        {
            dataIndex: 'production_centre_name',
            header: 'Production centre',
            editor: {
                xtype: 'simplecombo',
                store: Ext.Array.merge([''], window.CENTRE_OPTIONS),
                storeOptionsAreSpecial: true,
                listConfig: {
                    minWidth: 200
                }
            },
            filter: {
                type: 'list',
                options: window.CENTRE_OPTIONS
            }
        },
        {
            dataIndex: 'year',
            header: 'Year',
            editor: 'simplenumberfield',
        },
        {
            dataIndex: 'month',
            header: 'Month',
            editor: 'simplenumberfield',
        },
        {
            dataIndex: 'goal',
            header: 'Goal',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'crispr_goal',
            header: 'Crispr Goal',
            editor: 'simplenumberfield'
        },
        {
            dataIndex: 'goal_type',
            header: 'Goal type',
            editor: {
                xtype: 'simplecombo',
                store: Ext.Array.merge([''], window.GOAL_TYPES),
                storeOptionsAreSpecial: true,
                listConfig: {
                    minWidth: 200
                }
            },
            filter: {
                type: 'list',
                options: window.GOAL_TYPES
            }
        },
        {
            xtype:'actioncolumn',
            width:21,
            items: [{
                icon: 'images/icons/delete.png',
                tooltip: 'Delete',
                handler: function(grid, rowIndex, colIndex) {
                    var rec = grid.getStore().getAt(rowIndex);
                    if(confirm("Remove tracking goal?"))
                        grid.getStore().removeAt(rowIndex)
                }
            }]
        },
        {
            header: 'History',
            dataIndex: 'edit_link',
            renderer: function(value, metaData, record) {
                var pgId = record.getId();
                return Ext.String.format('<a href="{0}/tracking_goals/{1}/history">View history</a>', window.basePath, pgId);
            },
            sortable: false
        },
        {
            dataIndex: 'no_consortium_id',
            header: 'No Consortium',
            filter: {
                type: 'list',
                options: ['0','1'],
                value:'1',
                active: true
            },
           hidden: true,
           sortable: false
        }
    ]
});
