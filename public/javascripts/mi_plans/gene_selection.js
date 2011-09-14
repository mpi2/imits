Ext.require([
  'Imits.model.Gene',
  'Imits.widget.grid.RansackFiltersFeature',
  'Ext.ux.RowExpander',
  'Ext.selection.CheckboxModel'
]);
var grid;
Ext.onReady(function() {

  // Set listener for the clear button
  Ext.EventManager.addListener(
    'clear-search-terms-button',
    'click',
    function () {
      textarea = Ext.get('q_marker_symbol_or_mgi_accession_id_ci_in');
      textarea.dom.value = '';
      textarea.focus();
    }
  );

  grid = Ext.create('Ext.grid.Panel', {
    renderTo: 'mi-planning-grid',
    title: 'Please Select the Genes You Would Like to Register Interest In',
    iconCls: 'icon-grid',
    columnLines: true,
    store: {
      model: 'Imits.model.Gene',
      autoLoad: true,
      remoteSort: true,
      remoteFilter: true,
      pageSize: 20,
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
    manageResize: function() {
        var windowHeight = window.innerHeight - 30;
        if(!windowHeight) {
            windowHeight = document.documentElement.clientHeight - 30;
        }
        var newGridHeight = windowHeight - this.getEl().getTop();
        if(newGridHeight < 200) {
            newGridHeight = 200;
        }
        this.setHeight(newGridHeight);
        this.setWidth(Ext.get('mi-planning-grid').getWidth());
        this.doLayout();
    }
  });

  // Add pagination toolbar
  grid.addDocked(
      Ext.create('Ext.toolbar.Paging', {
        store: grid.getStore(),
        dock: 'bottom',
        displayInfo: true
      })
  );

  // Add widget toolbar
  function create_combobox ( label, label_width, store_source ) {
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
  }

  var consortium_combo = create_combobox( 'Consortium', 65, CONSORTIUM_COMBO_OPTS );
  var centre_combo     = create_combobox( 'Production Centre', 100, CENTRE_COMBO_OPTS );
  var priority_combo   = create_combobox( 'Priority', 47, PRIORITY_COMBO_OPTS );

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
          border: '10 5 3 10',
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
                  'mi_plan[mi_plan_status_id]': INTEREST_STATUS_ID,
                  authenticity_token: authenticityToken
                },
                failure: function (response) {
                  // TODO: Handle creation errors...
                  console.log('EPIC FAIL!');
                  console.log(response);
                }
              });
            });

            var store = grid.getStore();
            store.sync();
            store.load();

            grid.setLoading(false);

            return false;
          }
        }
      ]
    })
  );


  // Resize the grid and set up listeners
  grid.manageResize();
  Ext.EventManager.onWindowResize(grid.manageResize, grid);
  Ext.select('.collapsible-control').each(function(element) {
    element.addListener( 'click', function() { this.manageResize(); }, grid );
  });

  // Finally, do we need to pre-filter the grid?
  if (GENE_SEARCH_PARAMS) {
    filters = [];
    for (var field in GENE_SEARCH_PARAMS) {
      filters.push({ property: field, value: GENE_SEARCH_PARAMS[field] });
    }
    grid.getStore().filter(filters);
  }

});

