
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

  // Add the grid functionallity
  if ( Ext.get('gene-selection-table') ) {
    var grid = Ext.create(
      'Ext.ux.grid.TransformGrid',
      'gene-selection-table',
      {
        striperows: true,
        autoHeight: true,
        width: Ext.get('gene-selection-table-container').getWidth(),
        forceFit: true
      }
    );
    grid.render();
    Ext.EventManager.onWindowResize(function(){
      grid.setWidth(
        Ext.get('gene-selection-table-container').getWidth()
      );
    });
  }

});

