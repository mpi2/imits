function addHideRowLinks() {
    var parentEl = Ext.fly('distribution_centres_table');
    if (parentEl) {
        parentEl.on('click', function(event, target, options) {
            event.preventDefault();
            var inputField = Ext.get(target).prev('.destroy-field');
            inputField.set({value: true});
            Ext.get(target).parent().parent().remove();
        }, this, {delegate: 'a'});
    }
}

Ext.onReady(addHideRowLinks);

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

Ext.select('form .add-row').on("click", function(event){
  event.preventDefault();

  var data = Ext.get(this).getAttribute('data-fields');
  var id = Ext.get(this).getAttribute('data-object-id');
  var time = new Date().getTime();
  regexp = new RegExp(id, 'g');

  data = data.replace(regexp, time);

  if(!Ext.select("#distribution_centres_table:not(td > table) > tbody > tr:last").elements.length) {
    Ext.select("#distribution_centres_table tbody").insertSibling(data, 'append');
  } else {
    Ext.select("#distribution_centres_table:not(td > table) > tbody > tr:last").insertSibling(data, 'after');
  }

  Ext.select("#distribution_centres_table tr:last a.remove-row").on("click", function(e){
        e.preventDefault();
        Ext.get(this).up('tr').remove();
  });
  Ext.select('#distribution_centres_table tr:last .date-field').each(function(field) {
        var name = field.dom.name;
        var defaultValue = field.dom.value;
        var renderDiv = new Ext.Element(Ext.core.DomHelper.createDom({tag: 'div'}));
        renderDiv.replace(field);
        new Ext.form.field.Date({
            cls: 'date-field',
            renderTo: renderDiv,
            name: name,
            value: defaultValue,
            editable: false,
            format: 'd/m/Y'
        });
  });
});
