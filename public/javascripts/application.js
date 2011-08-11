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

/*
Kermits2.propertyNames = function(obj) {
    var retval = [];
    for(var i in obj) {retval.push(i);}
    return retval;
}
*/
function setInitialFocus() {
    var thing = Ext.select('.initial-focus').first();
    if(thing) {
        thing.focus();
    }
}
Ext.onReady(setInitialFocus);
/*
function clearSearchTermsHandler() {
    var el = Ext.get('clear-search-terms-button');

    if(el) {
        el.addListener('click', function() {
            var textarea = Ext.get('search-terms');
            textarea.dom.value = '';
            textarea.focus(250);
        });
    }
}
Ext.onReady(clearSearchTermsHandler);

function toggleMiAttemptsSwitchViewButton(button, pressed) {
    if(!pressed) {return;}

    var mask = new Ext.LoadMask(Ext.get('micro_injection_attempts_widget'),
        {msg: 'Reticulating columns...', removeMask: true});

    function intensiveOperation() {
        var grid = Netzke.page.microInjectionAttemptsWidget.grid;
        columnModel = grid.getColumnModel();

        var columnsToShow = MI_ATTEMPTS_VIEW_CONFIG[button.viewName];

        for(var idx = 0; idx < columnModel.getColumnCount(); ++idx) {
            var columnId = columnModel.getColumnId(idx);
            if(columnsToShow.indexOf(columnId) == -1) {
                columnModel.setHidden(idx, true);
            } else {
                columnModel.setHidden(idx, false);
            }
        }

        grid.syncSize();

        mask.hide();
        Ext.getBody().removeClass('wait');
    }

    Ext.getBody().addClass('wait');
    mask.show();

    setTimeout(intensiveOperation, 500);
}

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
*/

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

function hideDefaultCollapsibleFieldsets() {
    Ext.select('fieldset.collapsible.hide-by-default legend').each(function(elm ,comp, idx) {
        toggleCollapsibleFieldsetLegend( Ext.get(comp.elements[idx]) );
    });
}

Ext.onReady(setupCollapsibleFieldsets);
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

Ext.Loader.setConfig({
    enabled: true
});
Ext.Loader.setPath('Ext', '../extjs');
Ext.Loader.setPath('Ext.ux', '../extjs/examples/ux');
