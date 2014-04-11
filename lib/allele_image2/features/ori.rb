class AlleleImage2::Features::Ori < AlleleImage2::Features::DefaultFeature

  def detailed(renderer, image, options = {})
    drawing = Magick::Draw.new

    font_colour = feature.render_options[:font_colour]
    font_size   = feature.render_options[:font_size]

    width = renderer.options[:text_width] * "ori".length

    drawing.annotate(image, width, feature.render_options[:height], renderer.x, renderer.y - feature.render_options[:height], feature.label) do
      self.gravity     = Magick::CenterGravity
      self.font_weight = Magick::BoldWeight
      self.fill        = font_colour
      self.pointsize   = font_size
    end

    return image
  end

end