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

  // Initialize the grid
  var grid = Ext.create('Imits.widget.GeneGrid', { renderTo: 'mi-planning-grid' });

  // Resize the grid and set up listeners
  grid.manageResize();
  Ext.EventManager.onWindowResize(grid.manageResize, grid);
  Ext.select('.collapsible-control').each(function(element) {
    element.addListener( 'click', function() { this.manageResize(); }, grid );
  });

  // Do we need to pre-filter the grid?
  if ( !Ext.isEmpty(GENE_SEARCH_PARAMS) ) {
    filters = [];
    for (var field in GENE_SEARCH_PARAMS) {
      filters.push({ property: field, value: GENE_SEARCH_PARAMS[field] });
    }
    grid.getStore().filter(filters);
  }

});

