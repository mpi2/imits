$(function(){

$('#seq_1').html(colour_alignment($('#seq_1').html()));

function colour_alignment(seq){

    var match_char    =  /[ACTGN]/;
    var mismatch_char =  /[actgn]/;
    var delete_char   =  /-/;
    var insert_char   =  /[JLPYZ]/;


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
    base.append( make_span(buf, current_colour) );
    return base;
}