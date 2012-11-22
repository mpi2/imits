/*
 * Registers a callback which copies the csrf token into the
 * X-CSRF-Token header with each ajax request.  Necessary to 
 * work with rails applications which have fixed
 * CVE-2011-0447
*/

Ajax.Responders.register({
  onCreate: function(request) {
    var csrf_meta_tag = $$('meta[name=csrf-token]')[0];

    if (csrf_meta_tag) {
      var header = 'X-CSRF-Token',
          token = csrf_meta_tag.readAttribute('content');

      if (!request.options.requestHeaders) {
        request.options.requestHeaders = {};
      }
      request.options.requestHeaders[header] = token;
    }
  }
});


// Toggles to show/hide the ES Cell QC metrics
function setup_qc_metric_toggles() {
  $$('a.es_cell_qc_toggle').each( function(link) {
    link.stopObserving('click');
    link.observe( 'click', function(event) {
      event.stop();
      $(this).up('tr').next('tr.es_cell_qc').toggle();
    });
  });
}

function clearList() {
  $('gene_autocomplete').className = '';
  // Find and remove current list items
  var lis = $('gene_autocomplete').descendants();
  if (lis.length > 0) {
    lis.each(function(l) {
      l.remove();
    });
  };

  document.stopObserving('keydown');
}

document.observe('dom:loaded', function() {
  setup_qc_metric_toggles();
  if($('gene_marker_symbol')) {
    new Form.Element.Observer('gene_marker_symbol', 0.1, function(event) {
      var string = $F('gene_marker_symbol');
      if (string.length >= 3) {
        console.log(string)
        xhr = new Ajax.Request('/genes/autocomplete', {
          method:'post',
          parameters: {
            marker_symbol_cont: string
          },
          onSuccess: function(response) {
            clearList();

            $('gene_autocomplete').className = 'active';
            //
            var genes = response.responseJSON;

            genes.each(function(a) {
              var item = "<li class='gene'><a href='javascript:;' class='gene-item' data-id='"+a.id+"'>" + a.marker_symbol + "</a></li>";
              $('gene_autocomplete').insert(item);
            });

            $$('.gene-item').each(function(a) {
              a.observe("click", function() {
                var text = $(this).innerHTML;
                var id = $(this).readAttribute('data-id');
                Form.Element.setValue('gene_marker_symbol', '');
                $('gene_marker_symbol').placeholder = text
                $('gene_autocomplete').className = '';
                Form.Element.setValue('allele_gene_id', id);
                clearList()
              });
            });
          }
        })
      } else {
        clearList();
      }
    })

    document.observe('keydown', function(event) {
      if(event.which == 27) {
        clearList();
        Form.Element.setValue('gene_marker_symbol', '');
      }
    });
    
  }
});