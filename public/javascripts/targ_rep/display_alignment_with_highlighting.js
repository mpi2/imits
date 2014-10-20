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
  var annotation_table = $('#allele_sequence_annotations_table');
  if (annotation_table.length != 1){
    return
  }

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

function update_mutation_details(row){
    seq = $('#targ_rep_hdr_allele_sequence').val();
    wild_seq = $('#targ_rep_hdr_allele_wildtype_oligos_sequence').val();
    aligned_seq = $("#alignment_image").attr('data_seq');

    mutation_type = row.find(".annotation_mutation_type").val();
    start = row.find(".annotation_oligos_start_coordinate").val() - 1;
    end = row.find(".annotation_oligos_end_coordinate").val() - 1;
    length = row.find(".annotation_length").val() - 1;

    if (wild_seq == '' || seq == '' || (start >= end && mutation_type != 'Deletion')) {
        return;
    }

    if (mutation_type == 'Deletion'){
        insertion_count = length_of_insertions(aligned_seq, start);
        deletion_count = length_of_deletions(aligned_seq, start);
        deletion_str = wild_seq.substring(start + deletion_count -insertion_count + 1, start + length + deletion_count -insertion_count + 2);
        row.find(".annotation_actual").val('');
        row.find(".annotation_expected").val(deletion_str, start);
    } else if (mutation_type == 'Insertion'){
        insertion_str = seq.substring(start, end + 1);
        row.find(".annotation_actual").val(insertion_str);
        row.find(".annotation_expected").val('');
        row.find(".annotation_length").val(insertion_str.length);
    } else if (mutation_type == 'Substitution'){
        insertion_count = length_of_insertions(aligned_seq, start);
        deletion_count = length_of_deletions(aligned_seq, start);
        actual = seq.substring(start, end + 1);
        expected = wild_seq.substring(start + deletion_count - insertion_count, end + deletion_count - insertion_count + 1);
        row.find(".annotation_actual").val(actual);
        row.find(".annotation_expected").val(expected);
        row.find(".annotation_length").val(actual.length);
    }
}

function length_of_deletions(seq_str, start){
    del_count = 0;
    index_count = 0;
    for (i = 0; i < (seq_str.length -1); i++) {
        if (seq_str[i] != '[' && seq_str[i] != ']'){
            index_count += 1;
          if (index_count >= start){
            break;
          }
        }
        if (seq_str[i] == '-'){
            del_count += 1;
        }
    }
    return del_count
}

function length_of_insertions(seq_str, start){
    found_insertion = false
    ins_count = 0;
    index_count = 0;
    for (i = 0; i < (seq_str.length -1); i++) {
        if (seq_str[i] != '[' && seq_str[i] != ']'){
            index_count += 1;
          if (index_count >= start){
            break;
          }
        }
        if (found_insertion == true){
          ins_count += 1;
        }
        if (seq_str[i] == '['){
            found_insertion = true;
        } else if (seq_str[i] == ']'){
            found_insertion = false;
            ins_count -= 1
        }
    }
    return ins_count
}

function create_alignment_from_annotations(){
  var loaded_annotations = []
  $('#allele_sequence_annotations_table tbody tr:not(:hidden)').each(function(){
    row= $(this);
    if (row.has('.annotation_mutation_type').length != 0){
      mutation_type = return_value_from_field(row.find(".annotation_mutation_type"));
      oligos_start=   return_value_from_field(row.find(".annotation_oligos_start_coordinate"));
      oligos_end =    return_value_from_field(row.find(".annotation_oligos_end_coordinate"));
      actual =        return_value_from_field(row.find(".annotation_actual"));
      expected =      return_value_from_field(row.find(".annotation_expected"));
      loaded_annotations.push([mutation_type,oligos_start, oligos_end, actual, expected]);
    }
  })
  align_from_loaded_annotations(return_value_from_field($('#targ_rep_hdr_allele_sequence')), loaded_annotations)
}


function return_value_from_field(field){
  if (field.attr('data-value')) {
    return field.attr('data-value');
  } else{
    return field.val();
  }
}


function align_from_loaded_annotations(oligos_seq, annotations){
  annotations.sort(function(a,b){a[1]-b[1]});
  final_seq = oligos_seq;
  positional_correction = 0;
  annotations.forEach(function(element){
    mutation = '';
    mutation_start = parseInt(element[1]);
    mutation_type = element[0];
    mutation_length = Math.max(element[3].length, element[4].length);
    if (mutation_type == 'Deletion'){
      mutation = Array(mutation_length + 1).join("-");
      mutation_end = mutation_start;
      correction = mutation_length;
    } else if (mutation_type == 'Insertion'){
      mutation_start -= 1;
      mutation = '[' + element[3] + ']';
      mutation_end = mutation_start + element[3].length;
      correction = 2;
    } else {
      mutation = element[3].toLowerCase();
      mutation_start = mutation_start - 1;
      mutation_end = mutation_start + element[3].length;
      correction = 0
    }
    final_seq = final_seq.substring(0, mutation_start + positional_correction) + mutation + final_seq.substring(mutation_end + positional_correction, final_seq.length);
    positional_correction += correction;
  })

  coloured_sequence = highlight_sequence(final_seq);
  $("#alignment_image").attr('data_seq', final_seq);
  $("#alignment_image").empty().append(coloured_sequence);
}


function align_and_annotate(seq_1, seq_2){

  if (!(seq_1 && seq_2)){
    return 0;
  }
  final_seq = "";
  annotations= [];
  alignments = smith_walterman_alignment(seq_2, seq_1);
  wild = alignments[0];
  oligo = alignments[1];
  seq_length = wild.length;
  positional_adjustment = 0;

  for (i = 0; i < (seq_length); i++) {
    if (oligo[i] == '-'){
      j=0;
      for (k = i; k < (seq_length); k++) {
        if (oligo[k] == '-'){
          j += 1;
        } else {break}
      }
      final_seq = final_seq + Array(j+1).join("-");
      annotations.push(['Deletion', i-positional_adjustment, i-positional_adjustment, '', wild.substring(i, i+j)]);
      positional_adjustment += j;
      i += j -1;
      continue;

    } else if (wild[i] == '-'){
      j=0;
      for (k = i; k < (seq_length); k++) {
        if (wild[k] == '-'){
          j += 1;
        } else {break}
      }
      final_seq = final_seq + '[' + oligo.substring(i, i+j) + ']';
      annotations.push(['Insertion',i+1-positional_adjustment, i+j-positional_adjustment, oligo.substring(i, i+j), '']);
      i += j -1;
      continue;

    } else if (wild[i] != oligo[i]){
      j=0;
      for (k = i; k < (seq_length); k++) {
        if (wild[k] != oligo[k]){
          j += 1;
        } else {break}
      }
      final_seq = final_seq + oligo.substring(i, i+j).toLowerCase();
      annotations.push(['Substitution',i-positional_adjustment + 1, i+j-positional_adjustment, oligo.substring(i, i+j), wild.substring(i, i+j)]);
      i += j -1;
      continue;

    } else {
      final_seq = final_seq + oligo[i];
      continue;
    }
  }

  coloured_sequence = highlight_sequence(final_seq);
  $("#alignment_image").attr('data_seq', final_seq);
  $("#alignment_image").empty().append(coloured_sequence);
 // $("#alignment_image").replaceWith("<div id='sequence' style='width:400px; word-wrap:break-word;padding-top: 10px;padding-bottom: 20px;'>" + final_seq + "</div>");


}


function highlight_sequence(seq) {
    //a span to hold all the other spans
    var base = $("<div>", {style: 'width:400px; word-wrap:break-word;padding-top: 10px;padding-bottom: 20px;', class: "coloured_seq"});

    var match_no_read = /No/;
    if ( seq.match(match_no_read) ) {
      return base.text(seq);
    }

    //generates a coloured span
    function make_span(buf, colour) {
        //write our buffer out into a span
        attrs = { text: buf };
        if (colour) attrs.style =  "background-color:" + colour + "; color:#FFFFFF";

        return $("<span>", attrs);
    }

    var match_char    = /[ACTGN]/;
    var mismatch_char = /[actgn]/;
    var delete_char   = /-/;
    var insert_char   = /[\[\]]/;

    //get colour of read base
    function calculate_base_colour(base) {
      var base_colour = "";
      if ( match_char.test(base) ) {
        base_colour = '#468847';
      }
      else if ( mismatch_char.test(base) ) {
        base_colour = '#FE9A2E';
      }
      else if ( delete_char.test(base) ) {
        base_colour = '#b94A48';
      }
      else if ( insert_char.test(base) ) {
        base_colour = '#0000FF';
      }

      return base_colour;
    }

    var base_map = {
      'A': 'A',
      'T': 'T',
      'C': 'C',
      'G': 'G',
      '-': String.fromCharCode(8211),

    };

    var current_colour = "";
    var buf = "";
    var insertion = false;

    for ( var i = 0; i < seq.length; i++ ) {
        var nuc = seq.charAt(i);

        if (insertion == false){
        var colour = calculate_base_colour( nuc );
        }

        if (nuc == '['){
            insertion = true
        }

        if (nuc == ']'){
            insertion = false
        }
        //if the colours don't match or we're at the end of the string
        //we need to flush the buffer
        if ( colour != current_colour ) {
            //add to our base span (assuming it has something in)
            if ( buf )
                base.append( make_span(buf, current_colour) );

            //reset colour and restart buffer with the new char
            current_colour = colour;
            buf = base_map[nuc] ||  nuc;
        }
        else {
            buf += base_map[nuc] ||  nuc;
        }
    }

    //add anything remaining on the buffer (there will always be at least 1 base)
    base.append( make_span(buf, current_colour) );

    return base;
}