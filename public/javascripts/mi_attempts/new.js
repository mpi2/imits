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

    var genes = [];
    Ext.each(Kermits2.propertyNames(window.allClonesPartitionedByMarkerSymbol), function(gene) {
        if(gene == '') {
            genes.push([gene, '[All]']);
        } else {
            genes.push([gene, gene]);
        }
    });

    var geneCombo = new Ext.form.ComboBox({
        forceSelection: true,
        triggerAction: 'all',
        mode: 'local',
        lazyRender: true,
        store: genes,
        autoSelect: true,
        id: 'gene-combo'
    });

    geneCombo.onSelectListener = function(combo, record) {
        var gene = record.data[combo.valueField];
        cloneCombo.loadDataForGene(gene);
    }

    geneCombo.addListener('select', geneCombo.onSelectListener);

    var cloneCombo = new Ext.form.ComboBox({
        hiddenName: 'mi_attempt[clone_id]',
        hiddenId: 'mi_attempt_clone_id',
        lazyRender: true,
        forceSelection: true,
        triggerAction: 'all',
        mode: 'local',
        store: new Ext.data.JsonStore({
            root: 'rows',
            fields: ['id', 'clone_name']
        }),
        valueField: 'id',
        displayField: 'clone_name'
    });
    cloneCombo.loadDataForGene = function(gene) {
        this.store.loadData({
            rows: window.allClonesPartitionedByMarkerSymbol[gene]
        });
        this.setValue('');
        restOfForm.hide(false);
        form.dom.onsubmit = function() {return false;}
    }

    cloneCombo.addListener('select', function() {
        restOfForm.show(true);
        form.dom.onsubmit = null;
    });

    cloneCombo.loadDataForGene('');

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
            margins: '0 0 10 0',
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

    geneCombo.getEl().dom.value = '[All]';
}

Ext.onReady(function() {
    initDateFields();
    initNumberFields();
    onMiAttemptsNew();
});
