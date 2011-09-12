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

//function initDisableOnSubmitButtons() {
//    Ext.select('.disable-on-submit').each(function(button) {
//        button.addListener('click', function() {
//            button.set({
//                'disabled': 'disabled'
//            });
//            var form = button.up('form');
//            form.dom.submit();
//        });
//    });
//}
//Ext.onReady(initDisableOnSubmitButtons);
//
function toggleCollapsibleFieldsetLegend(legend) {
    var fieldset = legend.up('fieldset');
    var div      = fieldset.down('div');
    div.setVisibilityMode( Ext.Element.DISPLAY );
    div.toggle();
    fieldset.toggleCls('collapsible-content-hidden');
    fieldset.toggleCls('collapsible-content-shown');
}

function setupCollapsibleFieldsets() {
    var collapsibleLegends = Ext.select('fieldset.collapsible legend');
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

function googleAnalytics() {
    var _gaq = _gaq || [];
    _gaq.push(['_setAccount', 'UA-317752-10']);
    _gaq.push(['_trackPageview']);

    (function() {
        var ga = document.createElement('script');
        ga.type = 'text/javascript';
        ga.async = true;
        ga.src = ('https:' == document.location.protocol ? 'https://ssl' : 'http://www') + '.google-analytics.com/ga.js';
        var s = document.getElementsByTagName('script')[0];
        s.parentNode.insertBefore(ga, s);
    })();
}

Ext.util.Format.safeTextRenderer = function(value) {
    if (value === undefined || value === null) {
        value = '';
    }
    else {
        value = String(value);
    }

    if (!value) {
        return '\u00A0';
    }

    return Ext.util.Format.htmlEncode(value);
}

Ext.Loader.setConfig({
    enabled: true,
    paths: {
        'Imits': window.basePath + '/javascripts/Imits',
        'Imits.widget': window.basePath + '/javascripts/Imits/widget'
    }
});
Ext.Loader.setPath('Ext', window.basePath + '/extjs');
Ext.Loader.setPath('Ext.ux', window.basePath + '/extjs/examples/ux');

Ext.require('Imits.model.MiAttempt'); // TODO Why?!?!
