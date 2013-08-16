class AlleleImage2::Features::Ori < AlleleImage2::Features::DefaultFeature

  def detailed(renderer, image)
    drawing = Magick::Draw.new

    font_colour = @render_options[:font_colour]
    font_size   = @render_options[:font_size]

    width = renderer.options[:text_width] * "ori".length

    drawing.annotate(image, width, @render_options[:height], renderer.x, renderer.y - @render_options[:height], feature.label) do
      self.gravity     = Magick::CenterGravity
      self.font_weight = Magick::BoldWeight
      self.fill        = font_colour
      self.pointsize   = font_size
    end

    return image
  end

end