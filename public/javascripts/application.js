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
    // Find all instances of anchors with the data-confirm attribute, and add a confirm dialogue on click.
    var links=Ext.select('a[data-confirm]')
    for(var i=0; i<links.elements.length; i++) {
        links.elements[i].onclick = function(e) {
            if(!confirm(this.getAttribute('data-confirm'))) return false;
        }
    }

    // Find all instances of inputs with the data-confirm attribute, and add a confirm dialogue on form submission.
    var buttons=Ext.select('input[data-confirm]');
    for(var i=0; i<buttons.elements.length; i++) {
        var button = buttons.elements[i];
        button.form.onsubmit = function() {
            if(!confirm(button.getAttribute('data-confirm'))) return false;
        }
    }

    // Find all divs with the data-remoteurl attribute. This should be set to the page you want to load.
    var frames=Ext.select('div[data-remoteurl]');
    
    // Loop through all the divs
    for(var i=0; i<frames.elements.length; i++) {
        populateDiv(frames, i);
    }
})

function populateDiv(frames, i) {
    // Get the CSRF token. This is needed for rails to authenticate the Ajax request.
    var csrf_token = Ext.select('meta[name=csrf-token]').elements[0].content;
    // 'frame' is an HTML dom element. Not an Extjs object.
    var frame = frames.elements[i];
    // The url and the loading text are taken from the data-remoteurl and data-loadingtext attributes of the div.
    var url = frame.dataset.remoteurl;
    var loading_text = frame.dataset.loadingtext || 'Loading...';

    // The remotediv is a global class that is used to identify this type of div
    frame.className = frame.className + ' remotediv'
    // Add some placeholder text and loading gif to the div.
    frame.innerHTML = "<div class='loading'>\
        <p>\
            <img src='"+Rails.path+"/extjs/resources/themes/images/default/shared/blue-loading.gif' alt='Loading...' />\
            <span>"+loading_text+"(<a href='"+url+"' target='_blank'>or click here</a>)\</span>\
        </p>\
    </div>";

    Ext.Ajax.request({
        url: url,
        method: 'GET',
        params: {
            remote : true // This parameter is sent to identify to the controller that we don't want a layout. You need to set this up for controllers yourself.
        },
        headers: {
            'X-CSRF-Token' : csrf_token // Send the CSRF token with the request.
        },
        success: function(response){
            frame.innerHTML = response.responseText; // Replace the div placeholder with the response of the request.
        }
    })
}

$(document).ready(function() {
    // QC grid popup
    $('.report.qc_report .qc').mouseover(function() {

        var $link = $(this);

        var x = $link.offset().left;
        var y = $link.offset().top;

        var data = $link.data();

        var $popup = $('.cell-popup')

        $('dd.qc_type', $popup).text(data.column);
        $('dd.qc_centre', $popup).text(data.centre);
        $('dd.qc_consortium', $popup).text(data.consortium);
        $('dd.qc_gene', $popup).text(data.gene);
        $('dd.qc_result', $popup).text(data.result);
        $('dd.qc_es_cell', $popup).text(data.esCell);
        $('dd.qc_mutation_type', $popup).text(data.mutationType);
        $('dd.qc_colony', $popup).text(data.colonyName);

        if($link.hasClass('score')) {
            $('.qc_specific').hide();
        } else {
            $('.qc_specific').show();
        }

        if(data.threepLoxpScore) {
            $('dd.threep_loxp_score', $popup).text(data.threepLoxpScore);
            $('.threep_loxp_score', $popup).show();
        } else {
            $('.threep_loxp_score', $popup).hide();
        }

        $('.targeting_score', $popup).text(data.targetingScore);
        $('.cassette_score', $popup).text(data.cassetteScore);
        $('.insertion_score', $popup).text(data.insertionScore);

        if(data.distributionCentre && $link.hasClass('distribution_centre')) {
            $('.dc', $popup).show();
            $('.qc_distribution_centre', $popup).text(data.distributionCentre);
        } else {
            $('.dc', $popup).hide();
        }

        var positions = {
            left: x + 'px',
            top: y
        }

        var bottomEdge  = (y - window.pageYOffset) + $popup.height();
        var screenSpace = $(window).height();

        if(bottomEdge >= screenSpace) {
            positions.top = (positions.top - $popup.height())
        }

        console.log(positions)

        $popup
            .show()
            .css({
                top: positions.top,
                left: positions.left
            });

    })

    $('.report.qc_report .qc').mouseout(function() {
        $('.cell-popup').hide();
    })

    var $histoFrame = $('.histo');

    $histoFrame.each(function() {
        var $frame = $(this);
        var columnCount = 3;

        var targetingScore = $frame.data().targetingScore
        var cassetteScore  = $frame.data().cassetteScore
        var threeLoxpScore = $frame.data().threeLoxpScore
        var insertionScore = $frame.data().insertionScore

        var r = Raphael($frame.attr('id'));
        r.hbarchart(0, 2, 200, 44, [targetingScore, cassetteScore, threeLoxpScore, insertionScore], {
            to: 6,
            from: 0,
            colors: ['#FF6B6B', '#C7F464', '#4ECDC4', '#556270']
        }).hover(function() {
            cells = ['.targeting_score_cell', '.cassette_score_cell', '.threep_loxp_score_cell', '.insertion_score_cell'];
            klass = cells[this.columnCount];
            $cell = $(klass, $frame.parent().parent());
            $cell.addClass('column_hover')
        }, function() {
            cells = $('td', $frame.parent().parent());
            cells.removeClass('column_hover')
        }).each(function() {
            this.columnCount = columnCount;
            columnCount -= 1;
        })
    })
})