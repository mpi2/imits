Genoverse.Track.Vector = Genoverse.Track.extend({

    populateMenu: function ( feature ) {
        var deferred = $.Deferred();
        return( deferred );
    }
});

Genoverse.Track.Crispr = Genoverse.Track.extend({

    populateMenu: function ( feature ) {
        var deferred = $.Deferred();
        return( deferred );
    }
});

Genoverse.Track.Protein = Genoverse.Track.extend({

    populateMenu: function ( feature ) {
        var deferred = $.Deferred();
        return( deferred );
    }
});

Genoverse.Track.Model.Protein = Genoverse.Track.Model.extend({
  threshold : 10000,
  messages  : { threshold : 'Protein not displayed for regions larger than 10000' },
  buffer    : 0,

  parseData: function (data, start, end) {
    var index = 1;
    for ( var i = 0; i < data.length; i++ ) {
      this.insertFeature( data[i] );
    }
  },

  receiveData: function (data, start, end) {
    if ( data.error ) {
      create_alert(data.error);
    }
    else {
      this.base(data, start, end);
    }
  }
});

Genoverse.Track.View.Protein = Genoverse.Track.View.Sequence.extend({
  colors: {
    'default': '#CCCCCC',
    A: '#77dd88', G: '#77dd88',
    C: '#99ee66',
    D: '#55bb33', E: '#55bb33', N: '#55bb33', Q: '#55bb33',
    I: '#66bbff', L: '#66bbff', M: '#66bbff', V: '#66bbff',
    F: '#9999ff', W: '#9999ff', Y: '#9999ff',
    H: '#5555ff',
    K: '#ffcc77', R: '#ffcc77',
    P: '#eeaaaa',
    S: '#ff4455', T: '#ff4455',
    "*": '#ff0000'
  },
  labelColors: { 'default': '#000000'},

  init: function () {
    this.base();

    //add some classes to allow colouring of protein text
    var style = ".mutation { margin-right: 8px; }\n\
                 .mutation-highlighted { background-color: #ff0000 }\n";
    for ( var c in this.colors ) {
      color = this.colors[c];
      //create css classes like .protein_A { color:#77dd88 };
      style += '.protein_' + c + ' { color:'+ color +'; }\n';
    }

    $("<style type='text/css'>" + style + "</style>").appendTo("head");

  },

  draw: function (features, featureContext, labelContext, scale) {
    this.base(features, featureContext, labelContext, scale);
  },

  _drawBase: function(data) {
    data.context.fillStyle = data.boxColour;
    data.context.fillRect(data.x, data.y, data.width, data.height);

    if ( ! data.drawLabels ) return;

    data.context.fillStyle = data.textColour;
    var x = data.x + (data.width - this.labelWidth[data.base]) / 2;
    data.context.fillText(data.base, this.getTextCenter(data, data.base), data.y+this.labelYOffset );

    //need to compute width of label

    //don't draw numbers if the box is too small to hold 3 numbers
    if ( this.measureText(data.context, 999) > data.width ) return;

    //if its white change the colour because it won't show up
    if ( data.textColour == '#FFFFFF' )
      data.context.fillStyle = '#55bb33';

    data.context.fillText( data.idx, this.getTextCenter(data, data.idx), data.y+data.height+this.labelYOffset );
  },

  measureText: function (context, text) {
    //if its a number we dont want to cache all numbers, so just cache the number of
    //digits, which is stored in id
    var id = text;
    if ( text % 1 === 0 ) {
      var id = text.toString().length; //number of digits in the string
    }

    //for a number we want to measure the original text not thenumber of digits
    var size = this.labelWidth[id] || Math.ceil(context.measureText(text).width) + 1;

    return size;
  },

  getTextCenter: function (data, text) {
    var labelWidth = this.measureText(data.context, text);

    return data.x + (data.width - labelWidth) / 2;
  },

  drawSequence: function (feature, context, scale, width) {
    var drawLabels = this.labelWidth[this.widestLabel] < width*3 - 1;
    var start, bp;

    //draw the first base if one is set
    if ( feature.start_base ) {
      //swap start/end if its -ve stranded
      var idx = feature.strand == -1
              ? feature.start_index + feature.num_amino_acids
              : feature.start_index - 1;

      this._drawBase({
        context: context,
        boxColour: '#666666',
        x: feature.position[scale].X - (feature.start_base.len * scale),
        y: feature.position[scale].Y,
        width: scale*feature.start_base.len,
        height: this.featureHeight,
        drawLabels: drawLabels,
        textColour: '#FFFFFF',
        base: feature.start_base.aa,
        idx: idx
      });
    }

    if ( feature.end_base ) {
      var idx = feature.strand == -1
              ? feature.start_index-1
              : feature.start_index + feature.num_amino_acids;

      this._drawBase({
        context: context,
        boxColour: '#666666',
        x: feature.position[scale].X + (feature.sequence.length*3 * scale),
        y: feature.position[scale].Y,
        width: scale*feature.end_base.len,
        height: this.featureHeight,
        drawLabels: drawLabels,
        textColour: '#FFFFFF',
        base: feature.end_base.aa,
        idx: idx
      });
    }

    width *= 3;

    for (var i = 0; i < feature.sequence.length; i++) {
      start = feature.position[scale].X + (i*3) * scale;

      if (start < -scale || start > context.canvas.width) {
        continue;
      }


      var pos = i;
      var idx = feature.start_index + i;
      //display backwards if -ve gene
      if ( feature.strand == -1 ) {
        pos = ( feature.sequence.length - 1 ) - i;
        idx = ( feature.start_index + (feature.num_amino_acids-1) ) - i;
      }

      bp = feature.sequence.charAt(pos);

      this._drawBase({
        context: context,
        boxColour: (this.colors[bp] || this.colors['default']),
        x: start,
        y: feature.position[scale].Y,
        width: width,
        height: this.featureHeight,
        drawLabels: drawLabels,
        textColour: (this.labelColors[bp] || this.labelColors['default']),
        base: bp,
        idx: idx
      });
    }
  }

});