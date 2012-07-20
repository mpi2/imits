function addHideRowLinks() {
    var parentEl = Ext.fly('distribution_centres_table');
    parentEl.on('click', function(event, target, options) {
       event.preventDefault();
       var inputField = Ext.get(target).prev('.destroy-field');
       inputField.set({value:true});
       Ext.get(target).parent().parent().hide();
    }, this, {
      delegate: 'a'
    });
}


Ext.onReady(addHideRowLinks);

/*
$('form').on('click', '.hide_row', function(event) {
   $(this).prev('input[type=hidden]').val('1');
   $(this).closest('tr').hide();
   event.preventDefault();
});

$('form').on('click', '.remove_row', function(event) {
    $(this).closest('tr').remove();
    event.preventDefault();
});
*/

Ext.select('form .add-row').on("click", function(event){
  event.preventDefault();

  var data = Ext.get(this).getAttribute('data-fields');
  var id = Ext.get(this).getAttribute('data-object-id');
  var time = new Date().getTime();
  regexp = new RegExp(id, 'g');

  data = data.replace(regexp, time);

  Ext.select("#distribution_centres_table tr:last").insertSibling(data, 'after');

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
