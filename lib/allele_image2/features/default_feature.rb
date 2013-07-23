module AlleleImage2
  module Features
    class DefaultFeature

      def initialize(feature_name, options = {})

        @feature_name = feature_name
        
        @render_options = {
          :width => @feature_name.length * 12,
          :height => 40,
          :stroke => 'black',
          :colour => '#fff',
          :stroke_width => 2.5,
          :font_size => 10,
          :font_colour => 'black'
        }.merge(options)

      end

      def render(renderer)

        drawing = Magick::Draw.new
        drawing.stroke @render_options[:stroke]
        drawing.fill @render_options[:colour]
        drawing.rectangle(renderer.x, 0, renderer.x + @render_options[:width], @render_options[:height])
        drawing.draw(renderer.image)

        drawing.annotate(renderer.image, @render_options[:width], @render_options[:height], 0, @feature_name) do
          self.fill        = @render_options[:font_colour]
          self.font_weight = Magick::BoldWeight
          self.gravity     = Magick::CenterGravity
          self.pointsize   = @render_options[:font_size]
        end

      end

    end
  end
end