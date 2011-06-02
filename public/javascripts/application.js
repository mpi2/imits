window.onload = onWindowLoad;

function onWindowLoad() {
    setInitialFocus();
    clearSearchTermsHandler();
}

Ext.onReady(function() {
    initDateFields();
    initNumberFields();
});

function setInitialFocus() {
    var thing = Ext.DomQuery.jsSelect('.initial-focus')[0];
    if(thing) {
        thing.focus();
    }
}

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

function initDateFields() {
    var elements = Ext.DomQuery.jsSelect('.date-field');
    for(var i = 0; i != elements.length; ++i) {
        var textField = elements[i];
        var outerDiv = textField.parentNode;

        var renderDiv = Ext.DomHelper.createDom({tag: 'div'});
        outerDiv.replaceChild(renderDiv, textField);

        var dateField = new Ext.form.DateField({
            cls: 'date-field',
            renderTo: renderDiv,
            name: textField.name,
            editable: false,
            format: 'd/m/Y'
        });
    }
}

function initNumberFields() {
    var elements = Ext.DomQuery.jsSelect('.number-field');
    for(var i = 0; i != elements.length; ++i) {
        var textField = elements[i];
        var outerDiv = textField.parentNode;

        var renderDiv = Ext.DomHelper.createDom({tag: 'div'});
        outerDiv.replaceChild(renderDiv, textField);

        var numberField = new Ext.form.NumberField({
            cls: 'number-field',
            renderTo: renderDiv,
            name: textField.name,
            allowDecimals: false,
            allowNegative: false,
            width: 40
        });
    }
}
