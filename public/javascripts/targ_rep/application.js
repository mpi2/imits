$(function() {

  // Toggles to show/hide the ES Cell QC metrics
  $('.es_cell_qc_toggle').live('click', function() {
    $(this).parents('tr:first').next('tr.es_cell_qc').toggle();
    return false;
  })

  $('.es_cell_delete_row').live('click', function() {
    var $tr = $(this).parents('tr:first');

    if($(this).addClass('hard')) {
      $nested_input = $tr.find('input:first');
      var name = $nested_input.prop('name').replace(/nested/, '_destroy')
      var id = $nested_input.prop('id').replace(/nested/, '_destroy')
      var $hidden_field = $("<input type='hidden' name="+name+" id="+id+" value=1>")
      $(this).after($hidden_field)
      $tr.hide();
    } else {
      $tr.remove();
    }
    return false;
  })

  // Gene autocomplete
  $(function() {
    var $gene_input = $('#gene_marker_symbol');
    var $autocomplete_list = $('#gene_autocomplete');
    var $hidden_field = $('#targ_rep_allele_gene_id');

    $('.gene-item', $autocomplete_list).live('click', function() {
      $hidden_field.val($(this).attr('data-id'));
      $gene_input.val($(this).text());
      $autocomplete_list
        .removeClass('active')
        .html('');

      return false;  
    })

    if($gene_input.length) {
      $gene_input.bind('keyup.autocomplete', function(e) {
        var string = $(this).val();

        if(string.length >= 3) {
          $.get(basePath + 'genes?marker_symbol_cont='+string, function(data) {
            if(data.length) {
              $autocomplete_list.html('')
              $autocomplete_list.addClass('active');

              $.each(data, function(i, item) {
                $autocomplete_list.append($("<li class='gene'><a href='' class='gene-item' data-id='"+item.id+"'>" + item.marker_symbol + "</a></li>"))
              })
            }
          })
        }
      })
    }
  })

})

//function clearList() {
//  $('gene_autocomplete').className = '';
//  // Find and remove current list items
//  var lis = $('gene_autocomplete').descendants();
//  if (lis.length > 0) {
//    lis.each(function(l) {
//      l.remove();
//    });
//  };
//
//  document.stopObserving('keydown');
//}
//
//document.observe('dom:loaded', function() {
//  setup_qc_metric_toggles();
//  if($('gene_marker_symbol')) {
//    new Form.Element.Observer('gene_marker_symbol', 0.1, function(event) {
//      var string = $F('gene_marker_symbol');
//      if (string.length >= 3) {
//
//        xhr = new Ajax.Request('/genes', {
//          method:'get',
//          parameters: {
//            marker_symbol_cont: string
//          },
//          onSuccess: function(response) {
//            clearList();
//
//            $('gene_autocomplete').className = 'active';
//            //
//            var genes = response.responseJSON;
//
//            genes.each(function(a) {
//              var item = "<li class='gene'><a href='javascript:;' class='gene-item' data-id='"+a.id+"'>" + a.marker_symbol + "</a></li>";
//              $('gene_autocomplete').insert(item);
//            });
//
//            $$('.gene-item').each(function(a) {
//              a.observe("click", function() {
//                var text = $(this).innerHTML;
//                var id = $(this).readAttribute('data-id');
//                Form.Element.setValue('gene_marker_symbol', '');
//                $('gene_marker_symbol').placeholder = text
//                $('gene_autocomplete').className = '';
//                Form.Element.setValue('targ_rep_allele_gene_id', id);
//                clearList()
//              });
//            });
//          }
//        })
//      } else {
//        clearList();
//      }
//    })
//
//    document.observe('keydown', function(event) {
//      if(event.which == 27) {
//        clearList();
//        Form.Element.setValue('gene_marker_symbol', '');
//      }
//    });
//    
//  }
//});