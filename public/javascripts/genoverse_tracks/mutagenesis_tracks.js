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

String.prototype.splice = function(idx) {
    if (this.length < idx) {return this};
    return this.slice(0, idx) + '\n' + this.slice(idx).splice(idx) ;
};

var genoverseConfig = {
  container : '#genoverse', // Where to inject Genoverse (css/jQuery selector)
  // use genoverse to display the targeted region
  genome    : 'grcm38', // mouse, see genoverse/js/genomes/ for options
  chr       : chr_num,
  start     : seq_start - 2000,
  end       : seq_end + 2000,
  plugins   : [ 'controlPanel', 'karyotype', 'trackControls', 'resizer', 'fileDrop' ],
  tracks    : [
    // scalebar along top
    Genoverse.Track.Scalebar,
    // wildtype sequence track
    Genoverse.Track.extend({
      id        : 'SequenceTrack',
      name      : 'Sequence',
      url       : 'https://rest.ensembl.org/sequence/region/mouse/__CHR__:__START__-__END__?content-type=text/plain',
      model     : Genoverse.Track.Model.Sequence.Ensembl,
      view      : Genoverse.Track.View.Sequence,
      resizable : 'auto',
      100000    : false
    }),

    // Gene structure track
    Genoverse.Track.extend({
      id     : 'GenesTrack',
      name   : 'Genes',
      url    : 'https://rest.ensembl.org/overlap/region/mouse/__CHR__:__START__-__END__?feature=gene;feature=transcript;feature=exon;feature=cds;content-type=application/json',
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

    // Design track (showing crisprs used in this microinjection)
    Genoverse.Track.Crisprs.extend({
      id              : 'DesignTrack',
      name            : 'Design',
      url             : design_track_url,
      resizable       : 'auto',
      populateMenu : function (f) {
        var feature = this.track.model.featuresById[f.id];
        var atts = {
            Design: feature.design_id,
            "Feature_Type" : feature.name,
            Location: feature.chr + ':' + feature.start + '-' + feature.end,
            Sequence : feature.sequence
        };
        return atts;
      },

      // view      : Genoverse.Track.View.Sequence,
      setFeatureColor : function (f) { f.color = '#008000'; }
    }),


    // mutant sequence track (red boxes for deletions, blue for insertions)
    Genoverse.Track.MutantSeq.extend({
      id              : 'MutSequenceTrack',
      name            : 'Mut Sequence',
      url             : mutant_sequence_track_url,
      resizable       : 'auto',
      populateMenu : function (f) {
        var feature = this.track.model.featuresById[f.id];
        var atts = {
            "Modification_Type" : feature.mod_type,
            Location: feature.chr + ':' + feature.start + '-' + feature.end,
            "Reference_Sequence" : feature.ref_sequence.splice(100),
            "Alternate_Sequence" : feature.alt_sequence.splice(100)
            
        };
        return atts;
      },
      setFeatureColor : function (f) {
        var feature  = this.track.model.featuresById[f.id];
        switch(feature.mod_type) {
          case 'DEL':
              f.color = '#b94A48';
              break;
          case 'INDEL':
              f.color = '#b94A48';
              break;
          case 'INS':
              f.color = '#00BFFF';
              break;
          case 'SNP':
              f.color = '#FE9A2E';
              break;
          default:
              f.color = '#000000';
        }
      }
    }),
  ]
};

document.addEventListener('DOMContentLoaded', function () { window.genoverse = new Genoverse(genoverseConfig); });
