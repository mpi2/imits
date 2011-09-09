Ext.require('Imits.model.Gene');
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

  // var grid = Ext.create('Imits.widget.GeneGrid', { renderTo: 'mi-planning-grid' });

  grid = Ext.create('Ext.grid.Panel', {
    renderTo: 'mi-planning-grid',
    title: 'Genes',
    store: {
      model: 'Imits.model.Gene',
      autoLoad: true,
      remoteSort: true,
      remoteFilter: true,
      pageSize: 20,
    },
    columns: [
      {
        header: 'Gene',
        dataIndex: 'marker_symbol',
        readOnly: true
      },
      {
        header: 'MGI ID',
        dataIndex: 'mgi_accession_id',
        readOnly: true
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
        sortable: false
      },
      {
        header: 'Assigned MIs',
        dataIndex: 'pretty_print_assigned_mi_plans',
        readOnly: true,
        sortable: false
      },
      {
        header: 'MIs in Progress',
        dataIndex: 'pretty_print_mi_attempts_in_progress',
        readOnly: true,
        sortable: false
      },
      {
        header: 'GLT Mice',
        dataIndex: 'pretty_print_mi_attempts_genotype_confirmed',
        readOnly: true,
        sortable: false
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
  grid.addDocked(
      Ext.create('Ext.toolbar.Paging', {
        store: grid.getStore(),
        dock: 'bottom',
        displayInfo: true
      })
  );
  grid.manageResize();

  Ext.EventManager.onWindowResize(grid.manageResize, grid);
  Ext.select('.collapsible-control').each(function(element) {
    element.addListener('click', function() {
      this.manageResize();
    }, grid);
  });

  if (GENE_SEARCH_PARAMS) {
    filters = [];
    for (var field in GENE_SEARCH_PARAMS) {
      filters.push({ property: field, value: GENE_SEARCH_PARAMS[field] });
    }

    store = grid.getStore();
    store.filter(filters);
  }

});

