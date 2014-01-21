module AlleleImage2
  class Feature
    class NotRenderableError < RuntimeError; end

    attr_accessor :feature_name, :feature_type, :start, :stop, :orientation, :exon_rank

    def initialize(bio_feature, options = {})
      self.position = bio_feature.position
      note = bio_feature.to_hash['note']
      
      unless note
        raise NotRenderableError, "Missing feature name - " + self.inspect
      end

      self.feature_name = note.first
      self.feature_type = bio_feature.feature

      rank = bio_feature.to_hash['rank']

      if rank
        self.exon_rank = rank.first
      end

      return if options[:skip_renderable_check]

      if not AlleleImage2::RenderableFeatures.renderable?(feature_type, feature_name)
        raise NotRenderableError, self.inspect
      end
    end

    def position=(position)
      @start, @stop = position.scan(/-?\d+/).map(&:to_i)
      @orientation  = position.match(/^complement/) ? "reverse" : "forward"
    end

    def label
      render_options[:label] || feature_name
    end

    def render_options
      @render_options ||= AlleleImage2::RenderableFeatures.feature_properties(feature_type, feature_name)
    end

    def feature_class_name
      render_options[:class_name] || 'DefaultFeature'
    end

    def image
      @image ||= "AlleleImage2::Features::#{feature_class_name}".constantize.new(self)
    end

  end
end