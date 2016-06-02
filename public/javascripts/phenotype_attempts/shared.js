function replaceTextFieldWithExtField(selector, replacementCreationFunction) {
    Ext.select(selector).each(function(textField) {
        var name = textField.dom.name;
        var defaultValue = textField.dom.value;
        var renderDiv = new Ext.Element(Ext.core.DomHelper.createDom({tag: 'div'}));
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

Ext.select('.fill_other_occurences').on("change", function(event) {
  var value = Ext.get(this).getValue();
  var class_lookup = Ext.get(this).getAttribute('data-class-lookup');
  var div = Ext.select('.' + class_lookup);
  console.log(div);
  div.update(value);
 })

Ext.select('form #phenotype_attempt_cre_excision_required').on("change", function(e) {
  div = Ext.select('#cre-excision-fields');

  if(this.checked) {
    div.setStyle('display','block');
  } else {
    div.setStyle('display','none');
  }
})

Ext.select('form #phenotype_attempt_tat_cre').on("change", function(e) {
  div = Ext.select("#tat-cre-hidden-fields");

  if(this.checked) {
    div.setStyle('display','none');
  } else {
    div.setStyle('display','block');
  }
})




function processRestOfForm() {
    var restOfForm = Ext.get('rest-of-form');

    var subcontractstore = Ext.create('Ext.data.JsonStore', {
        model: 'MiPlanListViewModel',
        storeId: 'subcontractstore',
        proxy: {
            type: 'ajax',
            url: window.basePath + '/mi_plans/search_for_available_plans.json'
        },
        reader: {
            type: 'json'
        }

    });



    var subcontractlistview = Ext.create('Ext.grid.Panel', {
        id: 'sub_contract_list',
        width:1060,
        height:250,
        title:'Multiple Plans Found. Select the Sub Contract Plan',
        renderTo: 'mi_plan_list_phenotype',
        store: subcontractstore,
        singleSelect : true,
        viewConfig: {
            emptyText: 'No images to display'
        },

        columns: [{
            text: 'Consortium',
            flex: 50,
            dataIndex: 'consortium_name'
        },{
            text: 'Production Centre',
            flex: 50,
            dataIndex: 'production_centre_name'
        }
        ]
    });


    miplanlistview.on('selectionchange', function(view, nodes){
      restOfForm.getInputElement("phenotype_attempt[mi_plan_id]").set({ value: nodes[0].get('id') });
      Ext.get("phenotype_attempt_production_centre_name").set({ value: nodes[0].get('production_centre_name') });
    });

    miplanstorephenotype.on('load', function(){

        var recordIndex = miplanstorephenotype.find('id', restOfForm.getInputElement('phenotype_attempt[mi_plan_id]').getValue());
        if (recordIndex != -1) {
            miplanlistview.getSelectionModel().select(recordIndex);
        }
    });







