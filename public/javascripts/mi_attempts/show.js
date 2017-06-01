function addHideRowLinks() {
    var addDeleteRowArray = [/distribution_centres_\d+_table/, /colonies_\d+_table/, /genotype_primers_\d+_table/, /donors_\d+_table/, /reagents_\d+_table/];
    var tableElements = $('table');
    tableElements.each( function(index) {
      id =  tableElements[index].id;

      addDeleteRowArray.forEach(function(tableNameRegex) {
        tableRegex = tableNameRegex;

        if (tableRegex.test(id)){
          var parentEl = Ext.fly(id);
          if (parentEl) {
              parentEl.on('click', function(event, target, options) {
                  if(target.classList.length == 0) return;

                  event.preventDefault();
                  var inputField = Ext.get(target).prev('.destroy-field');
                  inputField.set({value: true});
                  row = Ext.get(target).parent().parent();
                  row.setVisibilityMode(Ext.Element.DISPLAY);
                  row.hide();
              }, this, {delegate: 'a'});
          }

        }
      })
    })
}

function addAutoSuggest() {
  document.getElementById("colonies_table_div").addEventListener("click",function(e) {
    if (e.target && e.target.matches("button.mgi_auto_suggest")) {
      mgi_button = e.target;
      mgi_button.disabled = true;
      mgiasa = mgi_button.parentNode.parentNode.querySelector(".mgi_allele_symbol_superscript");
      excludeimpc = mgi_button.parentNode.parentNode.querySelector(".without_impc_abbreviation");
      markerSymbol = document.getElementById("marker_symbol").value;
      productionCentreName = document.getElementById("production_centre_name").innerHTML;

      if (!markerSymbol && !productionCentreName && !excludeimpc && !mgiasa){
        alert("Could not suggest a Allele Symbol Superscript");
        mgi_button.disabled = false;
        return false
      }

      $.ajax({
        url: window.basePath + '/targ_rep/auto_suggest/mgi_allele.json', 
        type: "get", //send it through get method
        data: { 
          marker_symbol: markerSymbol, 
          production_centre_name: productionCentreName, 
        },
        success: function(result){
          findNextInSequence = result;
          console.log(findNextInSequence["without_impc_abbreviation"]);
          if (excludeimpc.checked){
            mgiasa.value = findNextInSequence["without_impc_abbreviation"];
          }
          else {
            mgiasa.value = findNextInSequence["with_impc_abbreviation"];
          }
          mgi_button.disabled = false;
          return true;
        },
        error: function(xhr){
          alert("Could not suggest a Allele Symbol Superscript");
          return false
          mgi_button.disabled = false;
        }
      });
    }
  })
}

Ext.onReady(function() {
  addHideRowLinks();
  addAutoSuggest();
})


Ext.select('form .add-row').on("click", function(event){
  event.preventDefault();

  var data     = Ext.get(this).getAttribute('data-fields');
  var id       = Ext.get(this).getAttribute('data-object-id');
  var table_id = Ext.get(this).getAttribute('data-table-id');
  var time     = new Date().getTime();
  regexp       = new RegExp(id, 'g');

  data = data.replace(regexp, time);

  Ext.select("#" + table_id + ":not(td > table) > tbody > tr:last").insertSibling(data, 'after');

  Ext.select("#" + table_id + " tr:last a.remove-row").on("click", function(e){
        e.preventDefault();
        Ext.get(this).up('tr').remove();
  });
  Ext.select("#" + table_id + " tr:last .date-field").each(function(field) {
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

