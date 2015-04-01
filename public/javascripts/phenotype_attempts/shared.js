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

