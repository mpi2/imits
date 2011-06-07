Ext.onReady(function() {
    initDateFields();
    initNumberFields();
});

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

function initTransformedComboBox(element) {
    var combo = new Ext.form.ComboBox({
        hiddenId: element.id,
        transform: element,
        triggerAction: 'all',
        forceSelection: true,
        autoSelect: false
    });

    combo.setValue('');

    return combo;
}

function onMiAttemptsNew() {
    var form = Ext.select('form.new.mi-attempt', true).first();
    if(! form) {return;}
    form.dom.onsubmit = function() {return false;};

    var restOfForm = Ext.get('rest-of-form');
    restOfForm.hide(false);

    var cloneCombo = initTransformedComboBox(form.child('select[name="mi_attempt[clone_id]"]'));
    console.log(cloneCombo.getStore());

    var cloneComboStore = new Ext.data.ArrayStore({

    });
/*
    var cloneCombo = new Ext.form.ComboBox({
        hiddenName: 'mi_attempt[clone_id]',
        hiddenId: 'mi_attempt_clone_id',
        forceSelection: true,
        triggerAction: 'all',
        mode: 'local',
        renderTo: 'mi_attempt_clone_id_combo',
        store: new Ext.data.ArrayStore({
            id: 0,
            fields: [
            'clone_id',
            'clone_name'
            ],
            data: [[1, 'item1'], [2, 'item2']]
        }),
        valueField: 'clone_id',
        displayField: 'clone_name'
    });
*/
    cloneCombo.addListener('select', function() {
        restOfForm.show(true);
        form.dom.onsubmit = null;
    });
}
window.onLoadHooks.push(onMiAttemptsNew);
