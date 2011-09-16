Ext.define('Imits.widget.GeneGrid', {
  extend: 'Imits.widget.Grid',
  requires: [
    'Imits.widget.Grid',
    'Imits.widget.grid.RansackFiltersFeature',
    'Ext.ux.RowExpander',
    'Ext.selection.CheckboxModel'
  ],
  title: 'Please Select the Genes You Would Like to Register Interest In',
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
  features: [{ ftype: 'ransack_filters', local: false }],
  columns: [
    {
      header: 'Gene',
      dataIndex: 'marker_symbol',
      readOnly: true,
      renderer: function(marker_symbol) {
        return Ext.String.format('<a href="http://www.knockoutmouse.org/martsearch/search?query='+marker_symbol+'" target="_blank">'+marker_symbol+'</a>')
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
    },
    {
      header: 'Non-Assigned MIs',
      dataIndex: 'pretty_print_non_assigned_mi_plans',
      readOnly: true,
      sortable: false,
      width: 250,
      flex: 1
    },
    {
      header: 'Assigned MIs',
      dataIndex: 'pretty_print_assigned_mi_plans',
      readOnly: true,
      sortable: false,
      width: 200,
      flex: 1
    },
    {
      header: 'MIs in Progress',
      dataIndex: 'pretty_print_mi_attempts_in_progress',
      readOnly: true,
      sortable: false,
      width: 200,
      flex: 1
    },
    {
      header: 'GLT Mice',
      dataIndex: 'pretty_print_mi_attempts_genotype_confirmed',
      readOnly: true,
      sortable: false,
      width: 200,
      flex: 1
    }
  ],

  /** @private **/
  createComboBox: function ( label, label_width, store_source ) {
    return Ext.create('Ext.form.ComboBox', {
      fieldLabel: label,
      labelAlign: 'right',
      labelWidth: label_width,
      store: Ext.create('Ext.data.Store', { data: store_source, fields: ['id','name'] }),
      queryMode: 'local',
      forceSelection: true,
      displayField: 'name',
      valueField: 'id'
    });
  },

  initComponent: function() {
    this.callParent();

    this.addDocked(
      Ext.create('Ext.toolbar.Paging', {
        store: this.getStore(),
        dock: 'bottom',
        displayInfo: true
      })
    );

    var grid             = this;
    var consortium_combo = this.createComboBox('Consortium',65,window.CONSORTIUM_COMBO_OPTS);
    var centre_combo     = this.createComboBox('Production Centre',100,window.CENTRE_COMBO_OPTS);
    var priority_combo   = this.createComboBox('Priority',47,window.PRIORITY_COMBO_OPTS);

    this.addDocked(
      Ext.create('Ext.toolbar.Toolbar', {
        dock: 'top',
        items: [
          consortium_combo,
          centre_combo,
          priority_combo,
          '  ',
          {
            text: 'Register Interest',
            cls:'x-btn-text-icon',
            iconCls: 'icon-add',
            handler: function () {
              var selected_genes = grid.selModel.selected;
              var consortium_id  = consortium_combo.getSubmitValue();
              var centre_id      = centre_combo.getSubmitValue();
              var priority_id    = priority_combo.getSubmitValue();

              if (selected_genes.length == 0) { alert('You must select some genes to register interest in'); return false; }
              if (consortium_id == null)      { alert('You must select a consortium'); return false; }
              if (priority_id == null)        { alert('You must selct a priority'); return false; }

              grid.setLoading(true);
              var failed_genes = [];

              selected_genes.each( function(gene_row) {
                var gene_id = gene_row.raw['id'];
                Ext.Ajax.request({
                  method: 'POST',
                  url: basePath + '/mi_plans.json',
                  params: {
                    'mi_plan[gene_id]': gene_id,
                    'mi_plan[consortium_id]': consortium_id,
                    'mi_plan[production_centre_id]': centre_id,
                    'mi_plan[mi_plan_priority_id]': priority_id,
                    'mi_plan[mi_plan_status_id]': window.INTEREST_STATUS_ID,
                    authenticity_token: authenticityToken
                  },
                  failure: function (response) { failed_genes.push(gene_row); }
                });
              });

              var store = grid.getStore();
              store.sync();
              store.load();

              grid.setLoading(false);

              if ( !Ext.isEmpty(failed_genes) ) {
                var error_str = 'An error occured trying to register interest on the following genes: ';
                error_str = error_str + failed_genes.join(', ');
                error_str = error_str + '. Please try registering your interest again.'
                alert(error_str);
              }

              return false;
            }
          }
        ]
      })
    );
  }
});
