$(function () {
  $('.add-row').on("click", function(event){
    target = $( this );
    event.preventDefault();

    var data = target.attr('data-fields');
    var id = target.attr('data-object-id');
    var table_id = target.attr('data-table-id');
    var time = new Date().getTime();
    regexp = new RegExp(id, 'g');

    data = data.replace(regexp, time);
    $("#" + table_id + " tbody tr:last").after(data);

    $("#" + table_id + " tr:last a.remove-row").on("click", function(e){
    e.preventDefault();
    $( this ).parent().parent().remove();
    create_alignment_from_annotations();
  });
  });
})

$(function() {
    var addDeleteRowArray = ['allele_sequence_annotations_table tbody']
    addDeleteRowArray.forEach(function(table_name) {
      var parentEl = $('#' + table_name );

      if (parentEl) {

           $( parentEl ).on("click", function(event) {
              event.preventDefault();
              if (event.target && event.target.className == "hide-row"){
                target = $(event.target);
                var inputField = target.siblings('.destroy-field');
                $( inputField ).val(true);
                row = target.parent().parent();
                row.hide();
                create_alignment_from_annotations();
              }
          });
          $( parentEl ).on("change", function(event) {
              event.preventDefault();
              classNamesToActOn = ["annotation_oligos_start_coordinate",
                                   "annotation_oligos_end_coordinate",
                                   "annotation_length"];
              if (event.target && $.inArray(event.target.className, classNamesToActOn) != -1 ){
                row = $(event.target).parent().parent();

                mutation_type = row.find(".annotation_mutation_type");
                start = row.find(".annotation_oligos_start_coordinate");
                end = row.find(".annotation_oligos_end_coordinate");
                if (mutation_type.val() == 'Deletion'){
                  if (event.target.className == 'annotation_oligos_start_coordinate'){
                    end.val(start.val());
                  } else if (event.target.className == 'annotation_oligos_end_coordinate'){
                    start.val(end.val());
                  }
                }
                update_mutation_details(row);
              }
              create_alignment_from_annotations();
          });
      }
    });
})


$(function() {
  button = $('#generate_annotations');

  button.on('click', function(){

    align_and_annotate( $('#targ_rep_hdr_allele_sequence').val(), $('#targ_rep_hdr_allele_wildtype_oligos_sequence').val());

    $('#allele_sequence_annotations_table tbody tr:not(:hidden)').each(function() {
      el = $(this).find("a");
      if (el){
        el.click();
      }
    });

    annotations.forEach(function(element){
      $('#annotation_add_link').click();
      row = $('#allele_sequence_annotations_table tbody tr:last');
      row.find(".annotation_mutation_type").val(element[0]);
      row.find(".annotation_oligos_start_coordinate").val(element[1]);
      row.find(".annotation_oligos_end_coordinate").val(element[2]);
      row.find(".annotation_actual").val(element[3]);
      row.find(".annotation_expected").val(element[4]);
      row.find(".annotation_length").val(Math.max(element[3].length, element[4].length));
    })
    create_alignment_from_annotations();
  });

  create_alignment_from_annotations();
});

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
    var $allele_type_gene_id = '#targ_rep_' + $('#allele_type').attr('value') + '_gene_id';
    var $allele_type_chr_id = '#targ_rep_' + $('#allele_type').attr('value') + '_chromosome';
    var $allele_type_strand_id = '#targ_rep_' + $('#allele_type').attr('value') + '_strand';

    var $gene_input = $('#gene_marker_symbol');
    var $autocomplete_list = $('#gene_autocomplete');
    var $hidden_field = $($allele_type_gene_id);
    var $field_chr = $($allele_type_chr_id);
    var $field_strand = $($allele_type_strand_id);

    $('.gene-item', $autocomplete_list).live('click', function() {
      $hidden_field.val($(this).attr('data-id'));
      $field_chr.val($(this).attr('data-chr'));
      $field_strand.val($(this).attr('data-strand'));
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
          $.get(basePath + '/genes.json?marker_symbol_cont='+string, function(data) {
            if(data.length) {
              $autocomplete_list.html('')
              $autocomplete_list.addClass('active');
              $autocomplete_list.append($("<li class='gene'>Please select a gene</li>"))
              $.each(data, function(i, item) {
                $autocomplete_list.append($("<li class='gene'><a href='' class='gene-item' data-chr='"+item.chr+"' data-strand='"+item.strand_name+"' data-id='"+item.id+"'>" + item.marker_symbol + "</a></li>"))
              })
            }
          })
        }
      })
    }
  })

})
