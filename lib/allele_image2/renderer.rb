module AlleleImage2
  require "RMagick"

  class Renderer
    attr_reader :image, :options

    attr_accessor :x, :y

    def initialize( construct, options = {} )
      raise "NotAlleleImageConstruct" unless construct.instance_of?( AlleleImage2::Construct )

      # assign our construct attribute
      @construct = construct

      #
      # NOTE
      # See sebs example of how to make this bit of logic more succinct
      # http://svn.internal.sanger.ac.uk/cgi-bin/viewvc.cgi/projects/htgt_to_targ_rep
      # /trunk/lib/molecular_structures.rb?revision=1679&root=htgt&view=markup
      #

      # handle the optional parameters passed in via params hash
      @options = {
        :bottom_margin         => 25,
        :feature_height        => 40,
        :top_margin            => 25,
        :font_size             => 18,
        :gap_width             => 10,
        :text_width            => 14,
        :text_height           => 22,
        :annotation_height     => 100,
        :sequence_stroke_width => 2.5,
        :cassetteonly          => false,
        :exon_min_width        => 20
      }.merge(options)

      # update the attributes from their default values
      @bottom_margin         = @options[:bottom_margin]
      @feature_height        = @options[:feature_height]
      @top_margin            = @options[:top_margin]
      @gap_width             = @options[:gap_width]
      @text_width            = @options[:text_width]
      @text_height           = @options[:text_height]
      @annotation_height     = @options[:annotation_height]
      @sequence_stroke_width = @options[:sequence_stroke_width]
      @font_size             = @options[:font_size]
      @image_height          = @bottom_margin + @feature_height + @top_margin
      @cassetteonly          = @options[:cassetteonly]
      @simple                = @construct.simple
      @mutation_type         = @options[:mutation_type]
      @exon_min_width        = @options[:exon_min_width]

      @split_exons = 0

      if @simple
        @annotation_height = 30
        @font_size = 30
      end

      @image = self.render

      return self
    end

    # The output of this method will get assigned to the @image attribute
    # of the AlleleImage2::Renderer class. This is what you get when you
    # call AlleleImage2::Image#render_image().
    def render
      # Construct the main image components
      main_image_list       = Magick::ImageList.new
      cassette_image_list   = render_cassette

      # returns cassette image only. Driven off the cassette? flag.
      if @cassetteonly
        main_image_list.push(cassette_image_list)
        return main_image_list
      end

      five_arm   = render_five_arm
      three_arm  = render_three_arm

      main_image_list.push(five_arm).push(cassette_image_list).push(three_arm)

      # get the width of the cassette + homology arms
      bb_width = main_image_list.append(false).columns

      # Actually makes more sense to push this functionality into the
      # flank drawing code. Just check for circular/linear and draw.
      five_flank  = render_five_flank
      three_flank = render_three_flank
      main_image_list.unshift(five_flank)
      main_image_list.push(three_flank)

      main_image = main_image_list.append(false)

      # If we are drawing a linear allele image and have a transcript id then display it
      unless ( @construct.circular )
        if @construct.transcript_id_label
          label_text             = "Transcript ID: #{@construct.transcript_id_label}"
          transcript_label_image = render_transcript_id_label( label_text )
          transcript_image_list  = Magick::ImageList.new
          transcript_image_list.push(main_image).push( transcript_label_image )
          main_image             = transcript_image_list.append(true)
        end
      end

      # Return the allele (i.e no backbone) unless this is a vector
      return main_image unless @construct.circular

      # Construct the backbone components and put the two images together
      vector_image_list   = Magick::ImageList.new
      backbone_image = render_backbone( :width => bb_width )

      vector_image_list.push(main_image).push(backbone_image)

      return vector_image_list.append(true)
    end

    def render_backbone( params = {} )
      backbone_image = Magick::ImageList.new
      five_flank_bb  = draw_empty_flank("5' arm backbone")
      three_flank_bb = draw_empty_flank("3' arm backbone")

      # we want to render the "AsiSI" somewhere else
      backbone_features = @construct.backbone_features.select { |feature| feature.label != "AsiSI" }
      params[:width]    = [ calculate_width( backbone_features ), params[:width] ].max
      backbone          = Magick::ImageList.new
      
      # teeze out the PGK-DTA-pA structure making sure the only thing b/w the PGK and the pA is the DTA
      wanted, rest = backbone_features.partition { |f| %w[pA DTA PGK].include?(f.label) }

      if wanted.empty?
        backbone.push( render_mutant_region( backbone_features, :width => params[:width], :section => "backbone" ) )
      else
        unexpected_features = backbone_features.select { |e| e.label != "DTA" and wanted.first.start < e.start and e.stop < wanted.last.stop }

        raise "Unexpected features in PGK-DTA-pA structure: [#{unexpected_features.map(&:label).join(', ')}]" unless unexpected_features.empty?

        rest_image   = render_mutant_region( rest,   :width => calculate_width(rest), :section => "backbone" )
        wanted_image = render_mutant_region( wanted, :width => calculate_width(wanted), :section => "backbone" )

        # create some padding between
        pad_width         = params[:width] - ( wanted_image.columns + rest_image.columns )
        pad_image_5_prime = render_mutant_region( [], :width => pad_width * 0.2, :section => "backbone" )
        pad_image_3_prime = render_mutant_region( [], :width => pad_width * 0.2, :section => "backbone" )
        middle_width = pad_width - ( pad_image_5_prime.columns + pad_image_3_prime.columns )
        pad_image_middle  = render_mutant_region( [], :width => middle_width, :section => "backbone" )
        backbone.push(pad_image_5_prime).push(wanted_image).push(pad_image_middle).push(rest_image).push(pad_image_3_prime)
      end

      backbone = backbone.append(false)
      main_bb  = Magick::ImageList.new

      # push the main backbone image onto the image list
      main_bb.push(backbone)

      # now add the label
      if @construct.backbone_label
        label_image = Magick::Image.new( backbone.columns, @text_height * 2 )
        label_image = draw_label( label_image, @construct.backbone_label, 0, 0, @text_height * 2 )
        main_bb.push( label_image )
      end

      backbone_image.push( five_flank_bb ).push( main_bb.append(true) ).push( three_flank_bb )
      backbone_image = backbone_image.append(false)

      return backbone_image
    end

    private
      # These methods return a Magick::Image object
      def render_cassette
        image = render_mutant_region( @construct.cassette_features, :label => @construct.cassette_label, :section => "cassette" )

        # Construct the annotation image
        image_list       = Magick::ImageList.new
        annotation_image = Magick::Image.new( image.columns, @annotation_height )

        # Stack the images
        image_list.push( annotation_image )
        image_list.push( image )

        return image_list.append(true)
      end

      def render_five_arm
        image = render_genomic_region( @construct.five_arm_features, :width => " 5' arm ".length * @text_width )
        # Construct the annotation image
        image_list       = Magick::ImageList.new
        annotation_image = Magick::Image.new( image.columns, @annotation_height )
        genomic          = @construct.five_arm_features.find do |feature|
          feature.feature_type == "misc_feature" and \
            feature.feature_name == "5 arm"
        end

        if genomic.nil?
          rcmb_primers = @construct.rcmb_primers_in(:five_arm_features)

          genomic      = AlleleImage2::Feature.new(
            Bio::Feature.new(
              "misc_feature",
              "#{rcmb_primers.first.start}, #{rcmb_primers.last.stop}"
            ).append( Bio::Feature::Qualifier.new( "note", "5 arm" ) )
          )
        end

        unless @simple
          homology_arm_label = @construct.bac_label ? "5' #{ @construct.bac_label }" : "5 arm"
          annotation_image = draw_homology_arm( annotation_image, homology_arm_label, genomic.stop - genomic.start )
        end

        # Stack the images
        image_list.push( annotation_image )
        image_list.push( image )

        return image_list.append(true)
      end

      def draw_empty_flank( region, height = @image_height, width = 100 )
        # let's create the 3 points we'll need
        a, b, c, e = [], [], [], []

        # set the points based on the flank "region"
        case region
          when "5' arm main"
            a, b, c, e = [width*0.5,height], [width*0.5,height*0.5], [width*0.75,height*0.5], [width,height*0.5]
          when "3' arm main"
            a, b, c, e = [width*0.5,height], [width*0.5,height*0.5], [width*0.25,height*0.5],  [0,height*0.5]
          when "5' arm backbone"
            a, b, c, e = [width*0.5,0],      [width*0.5,height*0.5], [width*0.75,height*0.5], [width,height*0.5]
          when "3' arm backbone"
            a, b, c, e = [width*0.5,0],      [width*0.5,height*0.5], [width*0.25,height*0.5],  [0,height*0.5]
          else
            raise "Not a valid region to render: #{region}"
        end

        # draw the image
        i = Magick::Image.new(width, height)
        d = Magick::Draw.new
        d.stroke_width(@sequence_stroke_width)
        d.fill("white")
        d.stroke("black")
        d.bezier(a.first, a.last, b.first, b.last, c.first, c.last)
        d.line(c.first, c.last, e.first, e.last)
        d.draw(i)

        # insert the AsiSI in here somewhere
        if region.match(/5' arm/)
          asisi   = Magick::Image.new( @text_width * "AsiSI".length, height )
          asisi   = draw_sequence( asisi, 0, height/2, asisi.columns, height/2 )
          feature = @construct.backbone_features.find { |feature| feature.feature_name == "AsiSI" }

          if region.match(/main/) and feature
            asisi = draw_feature(asisi, feature)
          end

          test  = Magick::ImageList.new
          test.push(i).push(asisi)
          i = test.append(false)
        end

        return i if region.match(/backbone/)

        # the linker to the other curved section
        l      = Magick::Image.new( width, calculate_labels_image_height )
        linker = Magick::Draw.new
        linker.stroke_width(@sequence_stroke_width)
        linker.fill("white")
        linker.stroke("black")
        linker.line( width * 0.5, 0, width * 0.5, l.rows )
        linker.draw(l)

        # create an ImageList to stack both images
        flank_image = Magick::ImageList.new
        flank_image.push(i).push(l)

        return flank_image.append(true)
      end

      def render_five_flank
        image = @construct.circular ? draw_empty_flank("5' arm main") : render_genomic_region( @construct.five_flank_features )

        # Construct the annotation image
        image_list       = Magick::ImageList.new
        annotation_image = Magick::Image.new( image.columns, @annotation_height )

        # Stack the images
        image_list.push( annotation_image )
        image_list.push( image )

        return image_list.append(true)
      end

      def render_three_arm
        image_list             = Magick::ImageList.new
        rcmb_primers           = @construct.rcmb_primers_in(:three_arm_features)
        three_arm_features     = []
        target_region_features = []
        loxp_region_features   = []

        if rcmb_primers.count == 2
          three_arm_features = @construct.three_arm_features
        else
          target_region_features = @construct.three_arm_features.select do |feature|
            feature.start >= rcmb_primers[0].start and \
            feature.start <= rcmb_primers[1].stop
          end
          loxp_region_features = @construct.three_arm_features.select do |feature|
            feature.start >= rcmb_primers[1].start and \
            feature.start <= rcmb_primers[2].stop and \
            feature.feature_type == "misc_feature" and \
            (feature.feature_name == "loxP" || feature.feature_name == "Downstream LoxP")
          end
          three_arm_features = @construct.three_arm_features.select do |feature|
            feature.start >= rcmb_primers[2].start and \
            feature.start <= rcmb_primers[3].stop
          end
        end

        image_list.push(render_genomic_region(target_region_features)) unless target_region_features.empty?
        image_list.push(render_mutant_region(loxp_region_features, :section => "loxp"))    unless loxp_region_features.empty?
        image_list.push(render_genomic_region(three_arm_features))     unless three_arm_features.empty?
        
        image = image_list.empty? ? render_genomic_region([]) : image_list.append(false)

        # For the (unlikely) case where we have nothing in the 3' arm,
        # construct an empty image with width = "3' arm".length()
        homology_arm_width = " 3' arm ".length * @text_width
        if image.columns < homology_arm_width
          padded_image  = Magick::ImageList.new
          padding_width = ( homology_arm_width - image.columns ) / 2
          padding_image = render_genomic_region( [], :width => padding_width )
          image         = padded_image.push( padding_image ).push( image ).push( padding_image.clone ).append(false)
        end

        # Construct the annotation image
        image_list       = Magick::ImageList.new
        annotation_image = Magick::Image.new( image.columns, @annotation_height )
        genomic          = @construct.three_arm_features.select do |feature|
          feature.feature_type == "misc_feature" and \
            feature.feature_name == "3 arm"
        end

        if genomic.size == 0
          rcmb_primers = @construct.rcmb_primers_in(:three_arm_features)
          if rcmb_primers.count == 2
            genomic.push(
              AlleleImage2::Feature.new(
                Bio::Feature.new(
                  "misc_feature",
                  "#{rcmb_primers.first.start}, #{rcmb_primers.last.stop}"
                ).append( Bio::Feature::Qualifier.new( "note", "3 arm" ) ) ) )
          else
            genomic.push(
              AlleleImage2::Feature.new(
                Bio::Feature.new(
                  "misc_feature",
                  "#{rcmb_primers[-2].start}, #{rcmb_primers[-1].stop}"
                ).append( Bio::Feature::Qualifier.new( "note", "3 arm" ) ) ) )
          end
        end

        unless @simple
          homology_arm_label = @construct.bac_label ? "3' #{ @construct.bac_label }" : "3 arm"
          annotation_image = draw_homology_arm( annotation_image, homology_arm_label, genomic.last.stop - genomic.first.start )
        end

        # Stack the images
        image_list.push( annotation_image )
        image_list.push( image )

        return image_list.append(true)
      end

      def render_three_flank
        image = @construct.circular ? draw_empty_flank("3' arm main") : render_genomic_region( @construct.three_flank_features )

        # Construct the annotation image
        image_list       = Magick::ImageList.new
        annotation_image = Magick::Image.new( image.columns, @annotation_height )

        # Stack the images
        image_list.push( annotation_image )
        image_list.push( image )

        return image_list.append(true)
      end

      # This needs to centralize the features it renders
      def render_mutant_region( features, params={} )
        cassette_features = insert_gaps_between( features )
        image_list        = Magick::ImageList.new
        features_width    = calculate_width( cassette_features )
        image_width       = params.include?(:width) ? params[:width] : features_width

        if params[:label]
          label_length = params[:label].split(/\n/).map { |e| e.length }.max
          if image_width < @text_width * label_length
            image_width = @text_width * label_length
          end
        end

        # Construct the main image
        image_height   = @image_height
        main_image     = Magick::Image.new( image_width, image_height )
        @x             = 0
        @y             = image_height / 2
        main_image     = draw_sequence( main_image, @x, image_height / 2, image_width, image_height / 2 )

        # Centralize the features on the image
        # features_width = calculate_width( cassette_features )

        @x             = ( image_width - features_width ) / 2
        
        cassette_features.each_with_index do |feature, index|
          feature_width = 0

          if feature.do_not_display
            next
          end

          if feature.label == "gap"
            feature_width = @gap_width
          elsif @simple && feature.feature_type == 'promoter'
            antibiotic_resistance = cassette_features[index + 1]
            draw_feature( main_image, feature, :related_feature => antibiotic_resistance )
            feature_width = @gap_width
          elsif @simple && (feature.label =~ /pA/ || feature.label =~ /SA/ || feature.label =~ /SD/)
            draw_feature( main_image, feature )
            feature_width = @gap_width
          else
            draw_feature( main_image, feature )
            feature_width = feature.image.width
          end
          @x += feature_width ? feature_width : 0
        end

        image_list.push(main_image)

        # Construct the label image
        unless ( @simple )
          if params[:label]
            label_image = Magick::Image.new( image_width, @text_height * 2 )
            label_image = draw_label( label_image, params[:label], 0, 0, @text_height * 2 )
            image_list.push( label_image )
          end
        end

        return image_list.append(true)
      end

      def render_genomic_region features, params={}
        exons       = []
        image_width = params[:width] || 50

        if features
          exons = features.select { |feature| feature.feature_type == "exon" }
        end

        image_list  = Magick::ImageList.new

        if exons and exons.count > 0
          image_width = calculate_genomic_region_width( exons, image_width )
        end

        # Construct the main image
        main_image   = Magick::Image.new( image_width, @image_height )
        main_image   = draw_sequence( main_image, 0, @image_height / 2, image_width, @image_height / 2 )

        calculate_first_exon_start( image_width, exons )
        @y = @image_height / 2

        features = []

        if exons.count >= 3
          # create an intervening sequence feature to bridge between first and last exons
          intervening_sequence = AlleleImage2::Feature.new(
          Bio::Feature.new( "intervening sequence", "1..2" ).append(
              Bio::Feature::Qualifier.new( "note", "intervening sequence" ) ) )
          intervening_sequence.simple = @simple

          features = insert_gaps_between( [ exons.first, intervening_sequence, exons.last ] )
        else
          features = insert_gaps_between( exons )
        end

        features.each do |feature|
          feature_width = 0

          if feature.do_not_display
            next
          end

          if feature.feature_name == "gap"
            feature_width = @gap_width
          elsif ( feature.feature_name.match(/5' fragment/) )
            draw_feature( main_image, feature )
            feature_width = @exon_min_width
          elsif ( feature.feature_name.match(/central fragment/) )
            draw_feature( main_image, feature )
            feature_width = @exon_min_width
          elsif ( feature.feature_name.match(/intervening sequence/) )
            draw_feature( main_image, feature )
            feature_width = @exon_min_width - 5
          else
            draw_feature( main_image, feature )
            feature_width = @text_width
          end
          @x += feature_width # update the x coordinate
        end

        image_list.push( main_image )

        return image_list.append(true)
      end

      def render_transcript_id_label( transcript_label_text )
        if ( @simple )
          label_image = Magick::Image.new( ( @text_width - 3 ) * transcript_label_text.length, @text_height * 2 )
          label_image = draw_simple_label( label_image, transcript_label_text, 0, 0, @text_height * 2 )
        else
          label_image = Magick::Image.new( @text_width * transcript_label_text.length, @text_height * 2 )
          label_image = draw_label( label_image, transcript_label_text, 0, 0, @text_height * 2 )
        end
        return label_image
      end

      def calculate_first_exon_start( image_width, exons )
        default_start = ( image_width - calculate_exon_image_width( exons.count ) ) / 2
        if exons.count == 0
          @x = default_start
        elsif exons.first.feature_name.match(/3' fragment/)
          @x = 0
        elsif exons.first.feature_name.match(/central fragment/)
          @x = 0
        else
          @x = default_start
        end

      end

      # DRAW METHODS

      # Need to get this method drawing exons as well
      def draw_feature( image, feature, options = {} )
        unless feature.do_not_display
          feature_renderer = feature.image
          feature_renderer.render( self, image, options )
        end
      end

      # draw the sequence
      def draw_sequence( image, x1, y1, x2, y2 )
        d = Magick::Draw.new

        d.stroke( @simple ? '#999' : "black" )
        d.stroke_width( @sequence_stroke_width )
        d.line( x1, y1, x2, y2 )
        d.draw( image )

        return image
      end

      # draw the homology arms
      def draw_homology_arm(image, name, length)
        d = Magick::Draw.new
        w = image.columns - 1
        h = image.rows / 7 # overhang
        y = 5 * h

        # Draw the lines
        d.stroke( "black" )
        d.stroke_width( @sequence_stroke_width )
        d.line( 0, y + h, 0, y ).draw( image )
        d.line( 0, y, w, y ).draw( image )
        d.line( w, y, w, y + h ).draw( image )

        # We want better labels here
        label_for = { "5 arm" => "5' arm", "3 arm" => "3' arm" }

        # annotate the block
        pointsize = @font_size
        d.annotate( image, w, y, 0, 0, "#{ label_for[ name ] || name }\n(#{ length } bp)" ) do
          self.fill        = "blue"
          self.gravity     = Magick::CenterGravity
          self.font_weight = Magick::BoldWeight
          self.pointsize   = pointsize
        end

        return image
      end

      def draw_label( image, label, x, y, height = @text_height )
        d = Magick::Draw.new

        unless @simple
          d.stroke( "black" )
          d.fill( "white" )
          d.draw( image )
          pointsize = @font_size
          d.annotate( image, image.columns, height, x, y, label ) do
            self.fill        = "blue"
            self.gravity     = Magick::CenterGravity
            self.font_weight = Magick::BoldWeight
            self.pointsize   = pointsize
          end
        end

        return image
      end

      def draw_simple_label( image, label, x, y, height = @text_height )
        d = Magick::Draw.new

        d.stroke( "black" )
        d.fill( "white" )
        d.draw( image )
        pointsize = 13
        d.annotate( image, image.columns, height, x, y, label ) do
          self.fill        = "black"
          self.gravity     = Magick::CenterGravity
          self.font_weight = Magick::BoldWeight
          self.pointsize   = pointsize
        end

        return image
      end

      # Draw the K-frame En2 SA feature
      #
      # @since  0.2.6
      # @param  [Magick::Image] the image to draw on
      # @param  [AlleleImage2::Feature] the feature to draw
      # @param  [Array<Num, Num>] the point to place drawing
      # @return [Magick::Image]
      def draw_en2_k_frame( image, feature, point )
        draw_cassette_feature( image, feature, point[0], point[1], :label => "En2 SA" )

        # write the annotation above
        pointsize = @font_size * 0.75
        atg_label = Magick::Draw.new
        atg_label.annotate( image, feature.image.width, @top_margin, point[0], 0, "ATG" ) do
          self.fill        = "black"
          self.gravity     = Magick::CenterGravity
          self.font_weight = Magick::BoldWeight
          self.font_style  = Magick::ItalicStyle
          self.pointsize   = pointsize
        end

        return image
      end

       # Bio::Feature.new( "polyA_site", "5..6" ).append( Bio::Feature::Qualifier.new( "note", "PGK pA" ) )
      def draw_pgk_dta_pa( image, feature, point )
        gap = AlleleImage2::Feature.new( Bio::Feature.new( "misc_feature", "1..1" ).append( Bio::Feature::Qualifier.new( "note", "gap" ) ) )
        pgk = AlleleImage2::Feature.new( Bio::Feature.new( "promoter", "1..2" ).append( Bio::Feature::Qualifier.new( "note", "PGK promoter" ) ) )
        dta = AlleleImage2::Feature.new( Bio::Feature.new( "CDS", "3..4" ).append( Bio::Feature::Qualifier.new( "note", "DTA" ) ) )
        pa  = AlleleImage2::Feature.new( Bio::Feature.new( "misc_feature", "5..6" ).append( Bio::Feature::Qualifier.new( "note", "PGK pA" ) ) )
        [ ( 1 .. ( feature.image.width - 100 ) / @gap_width ).collect { |x| gap }, pgk, dta, pa ].flatten.each do |sub_feature|
          feature_width = 0
          if sub_feature.feature_name == "gap"
            feature_width = @gap_width
          else
            draw_feature( image, sub_feature)
            feature_width = sub_feature.image.width
          end
          point[0] += feature_width # update the x coordinate
        end

        return image
      end

      def draw_pa_dta_pgk( image, feature, point )
        gap = AlleleImage2::Feature.new( Bio::Feature.new( "misc_feature", "1..1" ).append( Bio::Feature::Qualifier.new( "note", "gap" ) ) )
        pgk = AlleleImage2::Feature.new( Bio::Feature.new( "promoter", "complement(1..2)" ).append( Bio::Feature::Qualifier.new( "note", "PGK promoter" ) ) )
        dta = AlleleImage2::Feature.new( Bio::Feature.new( "CDS", "3..4" ).append( Bio::Feature::Qualifier.new( "note", "DTA" ) ) )
        pa  = AlleleImage2::Feature.new( Bio::Feature.new( "misc_feature", "5..6" ).append( Bio::Feature::Qualifier.new( "note", "PGK pA" ) ) )
        [ ( 1 .. ( feature.image.width - 100 ) / @gap_width ).collect { |x| gap }, pa, dta, pgk ].flatten.each do |sub_feature|
          feature_width = 0
          if sub_feature.feature_name == "gap"
            feature_width = @gap_width
          else
            draw_feature( image, sub_feature)
            feature_width = sub_feature.image.width
          end
          point[0] += feature_width # update the x coordinate
        end

        return image
      end

      # UTILITY METHODS
      def calculate_genomic_region_width( exons, min_image_width )
        # if there are no exons just return minimum width
        return min_image_width if exons.nil? or exons.empty?

        # for simple images
        if @simple
          
          # calculate the width more carefully if there are multiple exons
          if exons.count > 1
            num_elements = exons.count
            calc_width = 0
            # calculate the intervening sequence width relative to an exon size
            intervening_width = @exon_min_width + 2

            # calculate the overall width relative to the number of exons
            if num_elements > 2
              calc_width = ( 2 * @exon_min_width ) + intervening_width + ( @gap_width * 2 )
            else
              calc_width = ( num_elements * @exon_min_width ) + ( @gap_width * ( num_elements - 1 ) )
            end

            # use the minimum width if it's larger than the calculated width
            return [ calc_width, min_image_width ].max
          end

          # otherwise just return the minimum width
          return min_image_width

        end

        # central exon fragments should be drawn sandwiched between the cassette end and loxp
        if exons.count == 1 and exons[0].feature_name.match(/central fragment/)
          return @text_width
        end

        image_width = calculate_exon_image_width( exons.size ) + @gap_width * 2 # for padding either side

        return [ image_width, min_image_width ].max
      end

      # Return the width occupied by the exons based on the exon count
      def calculate_exon_image_width( count )        
        count = 3 if count >= 3
        calc_width = ( count * @exon_min_width ) + ( @gap_width * ( count - 1 ) )
        # allow for exon rank labels with min width
        return [ calc_width, @exon_min_width ].max
      end

      def calculate_labels_image_height
        num_cassette_label_rows = 2 # in case of "cassette type\(cassette label)"
        num_three_arm_features  = @construct.three_arm_features.select { |f| f.feature_name.match(/^target\s+exon\s+/) }.size

        # we want the maximum here
        # for example a 3' arm with 5 exons will have 5 EnsEMBL id labels drawn one under another
        [ num_cassette_label_rows, num_three_arm_features ].max * @text_height
      end

      # find sum of feature labels
      def calculate_width( features )
        width, gaps = 0, 0

        # loop through all the features and calculate an overall width
        features.each do |feature|

          if feature.do_not_display
            next
          end

          # for some simple features just add a gaps width
          if @simple && (feature.label == 'pA' || feature.feature_type == 'promoter' || feature.label =~ /SA/ || feature.label =~ /SD/)
            width += @gap_width # Add a little spacing
          elsif feature.feature_name == "gap"
            gaps += @gap_width
          else
            width += feature.image.width ? feature.image.width : 0
          end

        end
        width = ( width + gaps ) + 1

        return width.to_i
      end

      # Insert gaps around the SSR sites and between the exons
      #
      # @since  0.2.5
      # @param  [Array<AlleleImage2::Feature>] list of features
      # @return [Array<AlleleImage2::Feature>] list of features
      def insert_gaps_between( features )
        features_with_gaps = []
        gap_feature        = AlleleImage2::Feature.new( Bio::Feature.new( "misc_feature", "1..1" ).append( Bio::Feature::Qualifier.new( "note", "gap" ) ) )

        return features_with_gaps if features.nil?

        features.each_index do |current_index|
          features_with_gaps.push( features[current_index] )
          next_index = current_index + 1
          unless features[next_index].nil?
            consecutive_names = [ features[current_index].feature_name, features[next_index].feature_name ]
            consecutive_types = [ features[current_index].feature_type, features[next_index].feature_type ]
            if consecutive_names.include?("loxP") ||
               consecutive_names.include?("FRT")  ||
               consecutive_names.include?("Rox")  ||
               consecutive_names.include?("F3")   ||
               consecutive_names.include?("AttP") ||
               consecutive_names.include?("intervening sequence") ||
               consecutive_types.include?("exon")
              features_with_gaps.push( gap_feature )
            end
          end
        end

        return features_with_gaps
      end
  end
end
