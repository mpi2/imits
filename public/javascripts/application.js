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
    var thing = Ext.select('.initial-focus').first();
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

function replaceTextFieldWithExtField(selector, replacementCreationFunction) {
    Ext.select(selector).each(function(textField, composite, idx) {
        var renderDiv = Ext.DomHelper.createDom({tag: 'div'});
        var name = textField.dom.name;
        textField.replaceWith(renderDiv);

        replacementCreationFunction(renderDiv, name);
    });
}

function initDateFields() {
    replaceTextFieldWithExtField('.date-field', function(renderDiv, name) {
        new Ext.form.DateField({
            cls: 'date-field',
            renderTo: renderDiv,
            name: name,
            editable: false,
            format: 'd/m/Y'
        });
    });
}

function initNumberFields() {
    replaceTextFieldWithExtField('.number-field', function(renderDiv, name) {
        new Ext.form.NumberField({
            cls: 'number-field',
            renderTo: renderDiv,
            name: name,
            allowDecimals: false,
            allowNegative: false,
            width: 40
        });
    });
}
