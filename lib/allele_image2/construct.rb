module AlleleImage2

  class Construct
    attr_reader :backbone_features, :bac_label, :boundries, :circular, :features, :rcmb_primers, :simple

    def initialize options = {}

      @rcmb_primers   = initialize_rcmb_primers options[:features]
      @features       = replace_functional_units options[:features], AlleleImage2::FUNCTIONAL_UNITS
      @circular       = options[:circular]
      @cassette_label = options[:cassette_label]
      @backbone_label = options[:backbone_label]
      @bac_label      = options[:bac_label]
      @simple         = options[:simple]

      raise "NoRcmbPrimers" unless @rcmb_primers.size > 0

      initialize_boundries
      init_backbone_features if @circular
    end

    def rcmb_primers_in section
      rcmb_primers.values_at(boundries[section][0] .. boundries[section][1])
    end

    def cassette_label
      cassette_type = "Promoterless Cassette"
      promoters     = cassette_features.select { |f| f.feature_type() == "promoter" }

      if promoters.size > 0
        cassette_type = "Promoter-Driven Cassette"
      end

      return "#{ cassette_type }\n(#{ @cassette_label })"
    end

    def backbone_label
      return @backbone_label unless @circular

      backbone_type = "Non-DTA Containing Plasmid Backbone"
      dta_features  = backbone_features.select { |x| x.feature_name.match(/DTA/) }

      if dta_features.size > 0
        backbone_type = "DTA Containing Plasmid Backbone"
      end

      return "#{ backbone_type }\n(#{ @backbone_label })"
    end

    # These methods always return something
    # keep these the same, the initialize section method should change
    # still need these features stored in a array
    def cassette_features
      @cassette_features ||= initialize_section(:cassette_features)

      if @simple
        @cassette_features = @cassette_features.select {|f| AlleleImage2::SIMPLE_FEATURES.include?(f.feature_name) || AlleleImage2::SIMPLE_FEATURE_TYPES.include?(f.feature_type) }
      end

      @cassette_features = @cassette_features.reject { |f| f.feature_name == "Synthetic Cassette" }
    end

    def five_arm_features
      @five_arm_features ||= initialize_section(:five_arm_features)
    end

    def three_arm_features
      @three_arm_features ||= initialize_section(:three_arm_features)
    end

    # These would return nil depending on if the
    # Construct is an Allele or a Vector

    # Not 100% sure if these should be empty if the Construct is circular
    def five_flank_features
      return if @circular
      @features.select { |feature| feature.start() < @rcmb_primers.first.start() }
    end

    def three_flank_features
      return if @circular
      @features.select { |feature| feature.start() > @rcmb_primers.last.stop() }
    end

    private
      def initialize_rcmb_primers features
        rcmb_primers = features.select do |feature|
          feature.feature_type == 'primer_bind' and \
           RenderableFeatures.config[:primer_bind].keys.include?(feature.feature_name.downcase.to_sym)
        end
        if rcmb_primers.size > 0
          return rcmb_primers
        else
          return create_virtual_rcmb_primers( features )
        end
      end

      def create_virtual_rcmb_primers features
        critical_region = select_feature features, 'Critical Region'
        cassette        = select_feature features, 'Synthetic Cassette'
        three_arm       = select_feature features, '3 arm'
        five_arm        = select_feature features, '5 arm'

        #Knock Out Design
        if critical_region
          g5 = virtual_primer 'G5', five_arm.start, five_arm.start + 50
          u5 = virtual_primer 'U5', cassette.start - 50, cassette.start
          u3 = virtual_primer 'U3', cassette.stop, cassette.stop + 50
          d5 = virtual_primer 'D5', critical_region.stop, critical_region.stop + 50
          d3 = virtual_primer 'D3', three_arm.start - 50, three_arm.start
          g3 = virtual_primer 'G3', three_arm.stop - 50, three_arm.stop
          return [g5, u5, u3, d5, d3, g3]
        # Deletion/ Insertion Design
        else
          g5 = virtual_primer 'G5', five_arm.start, five_arm.start + 50
          u5 = virtual_primer 'U5', cassette.start - 50, cassette.start
          d3 = virtual_primer 'D3', cassette.stop, cassette.stop + 50
          g3 = virtual_primer 'G3', three_arm.stop - 50, three_arm.stop
          return [g5, u5, d3, g3]
        end
      end

      def select_feature features, feature_name
        feature = features.select {|feature| feature.feature_name == feature_name}
        raise "More than one feature with #{feature_name}" if feature.size > 1

        return feature.first
      end

      def virtual_primer feature_name, start, stop
        primer = Bio::Feature.new(
          "primer_bind",
          "#{start}, #{stop}"
        ).append Bio::Feature::Qualifier.new("note", feature_name)

        AlleleImage2::Feature.new(primer, :skip_renderable_check => true)
      end

      # create boundries hash for five arm / three arm and cassette
      # value is array of 2 indexes for rcbm_primers array, which correspond to that boundries start
      # and stop rcbm primers - e.g. 5-arm start oligo is G5, end oligo is U5, which is index 0 and 1 in rcmb array
      def initialize_boundries
        if @rcmb_primers.count == 4
          @boundries = { :five_arm_features => [0,1], :cassette_features => [1,2], :three_arm_features => [2,3] }
        else
          @boundries = { :five_arm_features => [0,1], :cassette_features => [1,2], :three_arm_features => [2,5] }
          if cassette_features.empty?
            @cassette_features  = nil
            @boundries = { :five_arm_features => [0,2], :cassette_features => [2,3], :three_arm_features => [3,5] }
          end
        end
      end

      def initialize_section(section)
        # ap :section => section, :start => @rcmb_primers[@boundries[section][0]].start, :boundries => @boundries
        @features.select do |f|
          f.start >= @rcmb_primers[@boundries[section][0]].start and \
          f.stop  <= @rcmb_primers[@boundries[section][1]].stop  and \
          not @rcmb_primers.map(&:feature_name).include?(f.feature_name)
        end
      end

      def init_backbone_features
        # retrieve and sort any features not within the bounds of the homology arms
        upstream_features   = @features.select { |feature| feature.start() > @rcmb_primers.last.stop()   }
        downstream_features = @features.select { |feature| feature.stop()  < @rcmb_primers.first.start() }

        # reverse the orientation on the backbone
        [downstream_features.reverse() + upstream_features.reverse()].flatten.map do |feature|
          feature.orientation = case feature.orientation
            when "forward" then "reverse"
            when "reverse" then "forward"
            else raise "InvalidOrientation"
          end
        end

        @backbone_features = downstream_features.reverse() + upstream_features.reverse()
      end

      # Replace the functional units within the list of features
      #
      # @since  0.2.7
      # @param  [Array<AlleleImage2::Feature>] the features to draw
      # @param  [Hash<Array String>]          the functional units
      # @return [Array<AlleleImage2::Feature>] the features to draw
      def replace_functional_units features, units
        units.sort{ |a,b| b[0].size <=> a[0].size }.each do |query, label|
          features.each_index do |feature_index|
            if features[ feature_index ].feature_name == query.first
              found_query = true
              query.each_index do |query_index|
                next_feature = features[ feature_index + query_index ]
                unless next_feature && query[ query_index ] == next_feature.feature_name
                  found_query = false
                end
              end
              if found_query
                # perhaps this should be its own function?
                start   = features[ feature_index ].start
                stop    = features[ feature_index + query.size - 1 ].stop
                bio_feature = Bio::Feature.new "misc_feature", "#{start}..#{stop}"
                bio_feature.append Bio::Feature::Qualifier.new("note", label)

                feature = AlleleImage2::Feature.new bio_feature
                features.slice! feature_index, query.size
                features.insert feature_index, feature
              end
            end
          end
        end
        return features
      end
  end

end
