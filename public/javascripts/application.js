window.onload = onWindowLoad;

function onWindowLoad() {
    setInitialFocus();
}

function setInitialFocus() {
    var thing = Ext.DomQuery.jsSelect('.initial-focus')[0];
    if(thing) {
        thing.focus();
    }
}

function toggleMiAttemptsSwitchViewButton(button, pressed) {
    if(!pressed) {return;}

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
}
