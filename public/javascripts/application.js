Ext.namespace('Kermits2');

Kermits2.propertyNames = function(obj) {
    var retval = [];
    for(i in obj) { retval.push(i); }
    return retval;
}

function setInitialFocus() {
    var thing = Ext.select('.initial-focus').first();
    if(thing) {
        thing.focus();
    }
}
Ext.onReady(setInitialFocus);

function clearSearchTermsHandler() {
    var el = document.getElementById('clear-search-terms-button');

    if(el) {
        el.onclick = function() {
            var textarea = document.getElementById('search-terms');
            textarea.innerHTML = '';
            textarea.focus();
        }
    }
}
Ext.onReady(clearSearchTermsHandler);

function toggleMiAttemptsSwitchViewButton(button, pressed) {
    if(!pressed) {return;}

    var mask = new Ext.LoadMask(Ext.get('micro_injection_attempts_widget'),
        {msg: 'Reticulating columns...', removeMask: true});

    function intensiveOperation() {
        var grid = Netzke.page.microInjectionAttemptsWidget.grid;
        columnModel = grid.getColumnModel();

        var columnsToShow = MI_ATTEMPTS_VIEW_CONFIG[button.viewName];

        for(var idx = 0; idx < columnModel.getColumnCount(); ++idx) {
            var columnId = columnModel.getColumnId(idx);
            if(columnsToShow.indexOf(columnId) == -1) {
                columnModel.setHidden(idx, true);
            } else {
                columnModel.setHidden(idx, false);
            }
        }

        grid.syncSize();

        mask.hide();
        Ext.getBody().removeClass('wait');
    }

    Ext.getBody().addClass('wait');
    mask.show();

    setTimeout(intensiveOperation, 500);
}
