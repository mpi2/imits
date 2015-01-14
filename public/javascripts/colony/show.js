jQuery(document).ready(	function() {

    function toggleDetails() {
        $(".toggle").each(function( index ) {

               $( this ).on({'click':function(event){

               var name = $( this ).data( "name" );
               var text = $( this ).text();

               if(text == "View")
                 $( this ).text("Hide");
               else
                 $( this ).text("View");

               $( "#" + name ).toggle();

               event.preventDefault();

            }});
        });
    }

    toggleDetails();

});

// var crispr_for_region_params = [
//     "assembly_id=GRCm38",
//     "species=Mouse"
// ];

// function build_uri_params( params_to_build ) {
//     var param_stub = "?";
//     var param_end = [
//         "chr=__CHR__",
//         "start=__START__",
//         "end=__END__",
//         "content-type=text/plain"
//     ];
//     params_to_build = params_to_build.concat( param_end );
//     var param_str = params_to_build.join("&");
//     return param_stub.concat( param_str );
// }

var genoverseConfig = {
  container : '#genoverse', // Where to inject Genoverse (css/jQuery selector)
  // use genoverse to display the targeted region
  genome    : 'grcm38', // mouse, see genoverse/js/genomes/ for options
  chr       : chr_num,
  start     : seq_start,
  end       : seq_end,
  plugins   : [ 'controlPanel', 'karyotype', 'trackControls', 'resizer', 'fileDrop' ],
  tracks    : [
    // scalebar along top
    Genoverse.Track.Scalebar,
    // wildtype sequence track
    Genoverse.Track.extend({
      name      : 'Sequence',
      url       : 'http://rest.ensembl.org/sequence/region/mouse/__CHR__:__START__-__END__?content-type=text/plain',
      model     : Genoverse.Track.Model.Sequence.Ensembl,
      view      : Genoverse.Track.View.Sequence,
      resizable : 'auto',
      100000    : false
    }),
    // mutant sequence track (red boxes for deletions, blue for insertions)

    // Gene structure track
    Genoverse.Track.extend({
      name   : 'Genes',
      url    : 'http://rest.ensembl.org/overlap/region/mouse/__CHR__:__START__-__END__?feature=gene;feature=transcript;feature=exon;feature=cds;content-type=application/json',
      height : 200,
      info   : 'Ensembl API genes & transcripts, see <a href="http://rest.ensembl.org/" target="_blank">rest.ensembl.org</a> for more details',

      // Different settings for different zoom level
      2000000: { // This one applies when > 2M base-pairs per screen
        labels : false
      },
      100000: { // more than 100K but less then 2M
        labels : true,
        model  : Genoverse.Track.Model.Gene.Ensembl,
        view   : Genoverse.Track.View.Gene.Ensembl
      },
      1: { // > 1 base-pair, but less then 100K
        labels : true,
        model  : Genoverse.Track.Model.Transcript.Ensembl,
        view   : Genoverse.Track.View.Transcript.Ensembl
      }
    }),

    // Vector track (showing where these are targeting)
    Genoverse.Track.Vector.extend({
      id              : 'VectorTrack',
      name            : 'Vector',
      url             : root_url + 'mutagenesis_factor/vector/' + mutagenesis_factor_id + '?feature=vectortrack;content-type=application/json',
      resizable       : 'auto',
      populateMenu : function (f) {
        var feature = this.track.model.featuresById[f.id];
        var atts = {
            Chr: feature.chr,
            Strand: feature.strand,
            Start: feature.start,
            End: feature.end,
            Vector: feature.vector_name,
            Backbone: feature.backbone_name,
            Cassette: feature.cassette_name,
            "Cassette Type": feature.cassette_type,
            "Cassette Start": feature.cassette_start,
            "Cassette End": feature.cassette_end
        };
        if ( feature.loxp_start && feature.loxp_end ) {
          atts["LoxP Start"] = feature.loxp_start;
          atts["LoxP End"]   = feature.loxp_end;
        };
        return atts;
      },
      model           : Genoverse.Track.Model.Transcript,
      view            : Genoverse.Track.View.Transcript,
      setFeatureColor : function (f) { f.color = '#008000'; }
    }),

    // Crisprs track (showing crisprs used in this microinjection)
    Genoverse.Track.Crispr.extend({
      id              : 'CrisprTrack',
      name            : 'Crisprs',
      url             : root_url + 'mutagenesis_factor/crisprs/' + mutagenesis_factor_id + '?feature=crisprtrack;content-type=application/json',
      resizable       : 'auto',
      populateMenu : function (f) {
        var feature = this.track.model.featuresById[f.id];
        var atts = {
            Chr: feature.chr,
            Start : feature.start,
            End : feature.end,
            Seq : feature.sequence
        };
        return atts;
      },
      model           : Genoverse.Track.Model.Transcript,
      view            : Genoverse.Track.View.Transcript,
      setFeatureColor : function (f) { f.color = '#008000'; }
    }),

    // wildtype protein track
    Genoverse.Track.Protein.extend({
      id         : 'ProteinWTTrack',
      name       : 'Protein',
      url        : root_url + "targ_rep/wge_searches/protein_translation_for_region?species=mouse&chr_name=__CHR__&chr_start=__START__&chr_end=__END__",
      model      : Genoverse.Track.Model.Protein,
      view       : Genoverse.Track.View.Protein,
      resizable  : 'auto',
      populateMenu : function (f) {
        var feature                 = this.track.model.featuresById[f.id];
        var sequence_with_spaces = feature.sequence.match(/.{1,10}/g).join('&nbsp;')
        var sequence_line_split  = sequence_with_spaces.match(/.{1,80}/g).join('<br />')
        var atts = {
          Chr: feature.chr_name,
          Start : feature.start,
          End : feature.end,
          Strand: feature.strand,
          Sequence: sequence_line_split,
          "Gene ID": feature.gene,
          "Transcript ID": feature.transcript,
          "Protein ID": feature.protein,
          "Start Phase": feature.start_phase,
          "End Phase": feature.end_phase,
          "Number amino acids": feature.num_amino_acids

//         #   "sequence"=>"???",
//         #   "start_index"=>1,
//         #   "end_base"=>nil,
//         #   "id"=>"ENSMUSE00000341663",
//         #   "start_base"=>{"len"=>"1", "codon"=>"GGA", "aa"=>"G"},
//         #   "end_phase"=>"1",
//         #   "rank"=>1,

        };
        return atts;
      }
      // ,
      // controls   : 'off',
      // unsortable : false
    })
    //,
    // show mutant protein track
  ]
};

document.addEventListener('DOMContentLoaded', function () { window.genoverse = new Genoverse(genoverseConfig); });
