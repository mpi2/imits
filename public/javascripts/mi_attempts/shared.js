function replaceTextFieldWithExtField(selector, replacementCreationFunction) {
    Ext.select(selector).each(function(textField) {
        var renderDiv = Ext.DomHelper.createDom({tag: 'div'});
        var name = textField.dom.name;
        var defaultValue = textField.dom.value;
        textField.replaceWith(renderDiv);

        replacementCreationFunction(renderDiv, name, defaultValue);
    });
}

function initDateFields() {
    replaceTextFieldWithExtField('.date-field', function(renderDiv, name, defaultValue) {
        new Ext.form.DateField({
            cls: 'date-field',
            renderTo: renderDiv,
            name: name,
            editable: false,
            format: 'd/m/Y',
            value: defaultValue
        });
    });
}

function initNumberFields() {
    replaceTextFieldWithExtField('.number-field', function(renderDiv, name, defaultValue) {
        new Ext.form.NumberField({
            cls: 'number-field',
            renderTo: renderDiv,
            name: name,
            allowDecimals: false,
            allowNegative: false,
            width: 40,
            value: defaultValue
        });
    });
}

function initSubmitButton() {
    var button = Ext.get('mi_attempt_submit');
    button.addListener('click', function() {
        button.set({
            'disabled': 'disabled'
        });
        var form = button.up('form');
        form.dom.submit();
    });
}

Ext.onReady(function() {
    initDateFields();
    initNumberFields();
    initSubmitButton();
});
