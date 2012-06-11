NO_BREAK_SPACE = '\u00A0';

(function () {
    // Inspired by http://zetafleet.com/blog/javascript-dateparse-for-iso-8601
    var origParse = Date.parse;
    Date.parse = function (date) {
        var timestamp = origParse(date);

        if(! isNaN(timestamp)) {
            return timestamp;
        }

        var matchData = /(\d{4})-(\d{2})-(\d{2})/.exec(date);
        if (matchData) {
            timestamp = Date.UTC(+matchData[1], +matchData[2] - 1, +matchData[3]);
        }

        return timestamp;
    };
}());

function setInitialFocus() {
    var thing = Ext.select('.initial-focus').first();
    if(thing) {
        thing.focus();
    }
}
Ext.onReady(setInitialFocus);

function initDisableOnSubmitButtons() {
    Ext.select('.disable-on-submit').each(function(button) {
        button.addListener('click', function() {
            button.set({
                'disabled': 'disabled'
            });
            var form = button.up('form');
            form.dom.submit();
        });
    });
}
Ext.onReady(initDisableOnSubmitButtons);

function toggleCollapsibleFieldsetLegend(legend) {
    var fieldset = legend.up('fieldset');
    var div      = fieldset.down('div');
    div.setVisibilityMode( Ext.Element.DISPLAY );
    div.toggle();
    fieldset.toggleCls('collapsible-content-hidden');
    fieldset.toggleCls('collapsible-content-shown');
}

function setupCollapsibleFieldsets() {
    var collapsibleLegends = Ext.select('fieldset.collapsible > legend');
    collapsibleLegends.addCls('collapsible-control');
    collapsibleLegends.each(function(elm, comp, idx) {
        elm.addListener('click', function() {
            toggleCollapsibleFieldsetLegend( Ext.get(comp.elements[idx]) )
        });
        elm.up('fieldset').addCls('collapsible-content-shown');
    });
}
Ext.onReady(setupCollapsibleFieldsets);

function hideDefaultCollapsibleFieldsets() {
    Ext.select('fieldset.collapsible.hide-by-default legend').each(function(elm ,comp, idx) {
        toggleCollapsibleFieldsetLegend( Ext.get(comp.elements[idx]) );
    });
}
Ext.onReady(hideDefaultCollapsibleFieldsets);

Ext.util.Format.safeTextRenderer = function(value) {
    if(Ext.isEmpty(value)) {
        value = window.NO_BREAK_SPACE;
    } else {
        value = String(value);
    }

    return Ext.util.Format.htmlEncode(value);
}

function addHideRowLinks() {
    Ext.select('#distribution_centres_table tr a.hide_row').each(function(link) {
      link.on("click", function(e) {
          e.preventDefault();
          var inputField = Ext.get(this).up('tr').select('.destroy-field');
          inputField.set({value:1});
          Ext.get(this).up('tr').hide();
      })
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

Ext.select('form .add_row').on("click", function(event){
  event.preventDefault();
  var data = Ext.get(this).getAttribute('data-fields');

  Ext.select("#distribution_centres_table tr:last").insertSibling(data, 'after');

  Ext.select("#distribution_centres_table tr:last a.remove_row").on("click", function(e){
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

Ext.Loader.setConfig({
    enabled: true,
    paths: {
        'Imits': window.basePath + '/javascripts/Imits',
        'Ext': window.basePath + '/extjs',
        'Ext.ux': window.basePath + '/extjs/examples/ux'
    }
});

if(Ext.isGecko) {
    Ext.require('Imits.data.Proxy');
    Ext.require('Imits.data.JsonWriter');
    Ext.require('Imits.model.MiAttempt');
    Ext.require('Imits.model.Gene');
}
