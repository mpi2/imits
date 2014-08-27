$(function(){

$('#seq_1').html(colour_alignment($('#seq_1').html()));
protein_ref = $('#ref_protein').html().split('\n')[1];
protein_seq = $('#protein_seq').html().split('\n')[1];

for (i = 0; i < (protein_seq.length); i++) {
  if (protein_ref[i] != protein_seq[i]){
    protein_seq = protein_seq.substring(0, i-1) + protein_seq[i].toLowerCase() + protein_seq.substring(i+1, protein_seq.length);
  }
}

protein_ref = protein_ref.substring(0, protein_seq.length) + protein_ref.substring(protein_seq.length, protein_ref.length).toLowerCase()

mapping = {};
mapping['match_char'] = /[]/;
mapping['mismatch_char'] = /[a-z]/;
mapping['delete_char'] = /[]/;
mapping['insert_char'] = /[]/;

$('#protein_seq').html(colour_alignment(protein_seq, mapping));

mapping = {};
mapping['match_char'] = /[]/;
mapping['mismatch_char'] = /[]/;
mapping['delete_char'] = /[a-z]/;
mapping['insert_char'] = /[]/;

$('#ref_protein').html(colour_alignment(protein_ref, mapping, true));
})

function colour_alignment(seq, mapping, upper){
    var mapping = mapping || {};
    var upper = upper || false;

    var match_char    = mapping['match_char'] || /[ACTGN]/;
    var mismatch_char = mapping['mismatch_char'] || /[actgn]/;
    var delete_char   = mapping['delete_char'] || /-/;
    var insert_char   = mapping['insert_char'] || /[JLPYZ]/;


    //a span to hold all the other spans
    var base = $("<span>");

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
      'N': 'N',
      'J': 'N',
      'L': 'A',
      'P': 'T',
      'Y': 'C',
      'Z': 'G',
      'X': 'X',
      '-' : String.fromCharCode(8211)
    };

    var current_colour = "";
    var buf = "";

    for ( var i = 0; i < seq.length; i++ ) {
        var nuc = seq.charAt(i);
        var colour = calculate_base_colour( nuc );

        //if the colours don't match or we're at the end of the string
        //we need to flush the buffer
        if ( colour != current_colour ) {
            //add to our base span (assuming it has something in)
            if ( buf )
                base.append( make_span(buf, current_colour) );

            //reset colour and restart buffer with the new char
            current_colour = colour;
            buf = base_map[nuc] || nuc;
        }
        else {
            buf += base_map[nuc] || nuc;
        }
    }

    //add anything remaining on the buffer (there will always be at least 1 base)
    if (upper){
    base.append( make_span(buf.toUpperCase(), current_colour) );
    } else {
    base.append( make_span(buf, current_colour) );}
    return base;
}