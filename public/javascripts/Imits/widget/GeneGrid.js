// Helper functions for cell templates - see in the grid below...
function split_mi_string (mi_string) {
  var mis = [];
  var pattern = /^\[(.+)\:(.+)\:(\d+)\]$/;
  Ext.Array.each( mi_string.split('</br>'), function(mi) {
    var match = pattern.exec(mi);
    mis.push({ consortium: match[1], production_centre: match[2], count: match[3] });
  });
  return mis;
}

function split_mi_plan_string (mi_plan_string) {
  var mips = [];
  var pattern_with_prod_cen = /^\[(.+)\:(.+)\:(.+)\]$/;
  var pattern_without_prod_cen = /^\[(.+)\:(.+)\]$/;
  Ext.Array.each( mi_plan_string.split('</br>'), function(mip) {
    var match = pattern_with_prod_cen.exec(mip);
    if ( match ) {
      mips.push({ consortium: match[1], production_centre: match[2], status: match[3], original: mip });
    } else {
      match = pattern_without_prod_cen.exec(mip);
      mips.push({ consortium: match[1], production_centre: null, status: match[2], original: mip });
    }
  });
  return mips;
}

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
      renderer: function(symbol) {
        return Ext.String.format('<a href="http://www.knockoutmouse.org/martsearch/search?query={0}" target="_blank">{0}</a>', symbol)
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
      flex: 1,
      xtype: 'templatecolumn',
      tpl: new Ext.XTemplate(
        '<tpl for="this.processedMIPs(pretty_print_non_assigned_mi_plans)">',
          '<tpl if="status == \'Interest\'">',
            '<a class="delete-mi-plan" title="delete planned micro-injection" data-marker_symbol="{parent.marker_symbol}" data-consortium="{consortium}" data-production_centre="{production_centre}" data-original={original} href="#">{original}</a></br>',
          '</tpl>',
          '<tpl if="status != \'Interest\'">',
            '{original}</br>',
          '</tpl>',
        '</tpl>',
        { processedMIPs: split_mi_plan_string }
      )
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
      header: 'Aborted MIs',
      dataIndex: 'pretty_print_aborted_mi_attempts',
      readOnly: true,
      sortable: false,
      width: 200,
      flex: 1,
      xtype: 'templatecolumn',
      tpl: new Ext.XTemplate(
        '<tpl for="this.processedMIs(pretty_print_aborted_mi_attempts)">',
          '<a href="'+basePath+'/mi_attempts?q[terms]={parent.marker_symbol}&q[production_centre_name]={production_centre}" target="_blank">[{consortium}:{production_centre}:{count}]</a></br>',
        '</tpl>',
        { processedMIs: split_mi_string }
      )
    },
    {
      header: 'MIs in Progress',
      dataIndex: 'pretty_print_mi_attempts_in_progress',
      readOnly: true,
      sortable: false,
      width: 200,
      flex: 1,
      xtype: 'templatecolumn',
      tpl: new Ext.XTemplate(
        '<tpl for="this.processedMIs(pretty_print_mi_attempts_in_progress)">',
          '<a href="'+basePath+'/mi_attempts?q[terms]={parent.marker_symbol}&q[production_centre_name]={production_centre}" target="_blank">[{consortium}:{production_centre}:{count}]</a></br>',
        '</tpl>',
        { processedMIs: split_mi_string }
      )
    },
    {
      header: 'GLT Mice',
      dataIndex: 'pretty_print_mi_attempts_genotype_confirmed',
      readOnly: true,
      sortable: false,
      width: 200,
      flex: 1,
      xtype: 'templatecolumn',
      tpl: new Ext.XTemplate(
        '<tpl for="this.processedMIs(pretty_print_mi_attempts_genotype_confirmed)">',
          '<a href="'+basePath+'/mi_attempts?q[terms]={parent.marker_symbol}&q[production_centre_name]={production_centre}" target="_blank">[{consortium}:{production_centre}:{count}]</a></br>',
        '</tpl>',
        { processedMIs: split_mi_string }
      )
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

  reloadStore: function() {
    var store = this.getStore();
    store.sync();
    store.load();
  },

  initComponent: function() {
    var grid = this;
    grid.callParent();

    // Add the bottom (pagination) toolbar
    grid.addDocked(
      Ext.create('Ext.toolbar.Paging', {
        store: grid.getStore(),
        dock: 'bottom',
        displayInfo: true
      })
    );

    // Add the top (gene selection) toolbar
    var consortium_combo = grid.createComboBox('Consortium',65,window.CONSORTIUM_COMBO_OPTS);
    var centre_combo     = grid.createComboBox('Production Centre',100,window.CENTRE_COMBO_OPTS);
    var priority_combo   = grid.createComboBox('Priority',47,window.PRIORITY_COMBO_OPTS);
    var selected_genes   = [];
    var failed_genes     = [];
    var gene_counter     = 0;

    grid.addDocked(
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
              selected_genes     = grid.selModel.selected;
              failed_genes       = [];
              gene_counter       = 0;
              var consortium_id  = consortium_combo.getSubmitValue();
              var centre_id      = centre_combo.getSubmitValue();
              var priority_id    = priority_combo.getSubmitValue();

              if (selected_genes.length == 0) { alert('You must select some genes to register interest in'); return false; }
              if (consortium_id == null)      { alert('You must select a consortium'); return false; }
              if (priority_id == null)        { alert('You must selct a priority'); return false; }

              grid.setLoading(true);

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
                  callback: function(opt,success,response) {
                    if (!success || response.status == 0) { failed_genes.push(gene_row.raw['marker_symbol']); }
                    reportGeneSelectionErrors();
                  }
                });
              });

            }
          }
        ]
      })
    );

    function reportGeneSelectionErrors() {
      gene_counter++;
      if ( ! (gene_counter < selected_genes.length) ) {
        if ( !Ext.isEmpty(failed_genes) ) {
          var error_str = 'An error occured trying to register interest on the following genes: ';
          error_str = error_str + failed_genes.join(', ');
          error_str = error_str + '. Please try registering your interest again.'
          alert(error_str);
        }

        grid.reloadStore();
        grid.setLoading(false);
        return false;
      }
    }

    // Add listeners to the .delete-mi-plan buttons
    Ext.get(grid.renderTo).on('click', function(event,target) {
        var marker_symbol     = target.getAttribute('data-marker_symbol');
        var consortium        = target.getAttribute('data-consortium');
        var production_centre = target.getAttribute('data-production_centre');
        var original          = target.getAttribute('data-original');

        var confirmed = confirm(
          'Are you sure you want to delete the planned MI for ' +
          marker_symbol + ' - ' + original + '?'
        );

        if ( confirmed ) {
          Ext.Ajax.request({
            method: 'DELETE',
            url: basePath + '/mi_plans.json',
            params: {
              marker_symbol: marker_symbol,
              consortium: consortium,
              production_centre: production_centre,
              authenticity_token: authenticityToken
            },
            callback: function(opt,success,response) {
              if (success) {
                grid.reloadStore();
              } else {
                alert('There was an error deleting the MI plan. Please try again.');
              }
            }
          });
        }
      },
      this,
      { delegate: 'a.delete-mi-plan' }
    );


  }
});
