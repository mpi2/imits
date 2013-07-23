module AlleleImage2
  class Feature
    class NotRenderableError < RuntimeError; end

    attr_accessor :feature_name, :feature_type, :start, :stop, :orientation

    def initialize(bio_feature)
      self.position = bio_feature.position
      self.note = bio_feature.to_hash['note']
      self.feature_type = bio_feature.feature

      unless AlleleImage2::RenderableFeatures.renderable?(feature_type, feature_name)
        raise NotRenderableError, self.inspect
      end
    end

    def note=(note)
      self.feature_name = note.first if note
    end

    def position=(position)
      @start, @stop = position.scan(/-?\d+/)
      @orientation  = position.match(/^complement/) ? "reverse" : "forward"
    end

    def render_options
      AlleleImage2::RenderableFeatures.feature_properties(feature_type, feature_name)
    end

    def feature_class_name
      render_options[:class_name] || 'DefaultFeature'
    end

    def image
      "AlleleImage2::Features::#{feature_class_name}".constantize.new(feature_name, render_options)
    end
  end
end