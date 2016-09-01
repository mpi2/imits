function replaceTextFieldWithExtField(selector, replacementCreationFunction) {
    Ext.select(selector).each(function (textField) {
        var name = textField.dom.name;
        var defaultValue = textField.dom.value;
        var renderDiv = new Ext.Element(Ext.core.DomHelper.createDom({tag: 'div', 'data-name-of-replaced': name}));
        renderDiv.replace(textField);

        replacementCreationFunction(renderDiv, name, defaultValue);
    });
}

function initNumberFields() {
    replaceTextFieldWithExtField('.number-field', function(renderDiv, name, defaultValue) {
        new Ext.form.field.Number({
            cls: 'number-field',
            renderTo: renderDiv,
            name: name,
            value: defaultValue,
            width: 40,
            allowDecimals: false,
            minValue: 0,
            hideTrigger: true,
            keyNavEnabled: false,
            mouseWheelEnabled: false
        });
    });
}

function initDateFields() {
    replaceTextFieldWithExtField('.date-field', function(renderDiv, name, defaultValue) {
        new Ext.form.field.Date({
            cls: 'date-field',
            renderTo: renderDiv,
            name: name,
            value: defaultValue,
            editable: false,
            format: 'd/m/Y'
        });
    });
}

Ext.onReady(initNumberFields);
Ext.onReady(initDateFields);
