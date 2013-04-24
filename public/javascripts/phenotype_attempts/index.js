function clearSearchTermsHandler() {
    var el = Ext.get('clear-search-terms-button');

    if(el) {
        el.addListener('click', function() {
            var textarea = Ext.get('search-terms');
            textarea.dom.value = '';
            textarea.focus(250);
        });
    }
}

Ext.onReady(function() {
    var grid;
    if (FULL_ACCESS == true){
        grid = Ext.create('Imits.widget.PhenotypeAttemptsGrid', {
            renderTo: 'phenotype-attempts-grid'
        });
    }
    else {
        grid = Ext.create('Imits.widget.PhenotypeAttemptsGridGeneral', {
            renderTo: 'phenotype-attempts-grid'
        });
    }
    Ext.EventManager.onWindowResize(grid.manageResize, grid);
    grid.manageResize();

    Ext.select('.collapsible-control').each(function(element) {
        element.addListener('click', function() {
            this.manageResize();
        }, grid);
    });

    clearSearchTermsHandler();
});
