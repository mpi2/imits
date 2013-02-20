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

function getMetaContents(mn){
  var m = document.getElementsByTagName('meta')
  for(var i in m){
   if(m[i].name == mn){
     return m[i].content;
   }
  }
}

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

Ext.onReady(function() {
    links=Ext.select('a[data-confirm]')
    for(var i=0; i<links.elements.length; i++) {
        links.elements[i].addEventListener('click', function(e) {
            if(!confirm(this.getAttribute('data-confirm'))) e.preventDefault();
        })
    }

    buttons=Ext.select('input[data-confirm]')
    for(var i=0; i<buttons.elements.length; i++) {
        var button = buttons.elements[i]
        button.parentElement.parentElement.addEventListener('submit', function(e) {
            if(!confirm(button.getAttribute('data-confirm'))) e.preventDefault();
        })
    }
})