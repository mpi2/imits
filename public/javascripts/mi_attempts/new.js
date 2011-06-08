function replaceTextFieldWithExtField(selector, replacementCreationFunction) {
    Ext.select(selector).each(function(textField) {
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

function onMiAttemptsNew() {
    var form = Ext.select('form.new.mi-attempt', true).first();
    if(! form) {return;}
    form.dom.onsubmit = function() {return false;};

    var restOfForm = Ext.get('rest-of-form');
    restOfForm.hide(false);

    var cloneRecord = Ext.data.Record.create([
        {name: 'id'},
        {name: 'clone_name'}
    ]);

    var cloneReader = new Ext.data.JsonReader({
        idProperty: 'id',
        root: 'rows',
        totalProperty: 'results',
        fields: ['id', 'clone_name']
    });

    var cloneComboStore = new Ext.data.Store({reader: cloneReader}, cloneRecord);

    var geneCombo = new Ext.form.ComboBox({
        forceSelection: true,
        triggerAction: 'all',
        mode: 'local',
        lazyRender: true,
        store: new Ext.data.ArrayStore({
            id: 0,
            fields: [
            'myId',
            'displayText'
            ],
            data: [[1, 'item1'], [2, 'item2']]
        }),
        valueField: 'myId',
        displayField: 'displayText'
    });

    var cloneCombo = new Ext.form.ComboBox({
        hiddenName: 'mi_attempt[clone_id]',
        hiddenId: 'mi_attempt_clone_id',
        lazyRender: true,
        forceSelection: true,
        triggerAction: 'all',
        mode: 'local',
        store: cloneComboStore,
        valueField: 'id',
        displayField: 'clone_name'
    });

    cloneCombo.setValue('');

    cloneCombo.addListener('select', function() {
        restOfForm.show(true);
        form.dom.onsubmit = null;
    });

    var clonePanel = new Ext.Panel({
        layout: 'vbox',
        renderTo: 'mi_attempt_clone_id_combo',
        height: 90,
        border: false,
        items: [
        {
            xtype: 'panel',
            layout: 'vbox',
            height: 40,
            border: false,
            items: [
            {
                xtype: 'label',
                text: 'Marker symbol'
            },
            geneCombo
            ]
        },
        {
            xtype: 'panel',
            layout: 'vbox',
            height: 40,
            border: false,
            items: [
            {
                xtype: 'label',
                text: 'ES cell clone name',
                forId: 'mi_attempt_clone_id'
            },
            cloneCombo
            ]
        }
        ]
    });
}

Ext.onReady(function() {
    initDateFields();
    initNumberFields();
    onMiAttemptsNew();
});
