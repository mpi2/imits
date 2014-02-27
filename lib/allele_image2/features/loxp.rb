class AlleleImage2::Features::Loxp < AlleleImage2::Features::DefaultFeature

  # From RMagick docs
  # drawing.polygon(x1, y1,...,xN, yN)
  # drawing.annotate(img, width, height, x, y, text)

  def detailed(renderer, image, options = {})

   # Draw the triangle
   drawing = Magick::Draw.new
   drawing.stroke feature.render_options[:stroke]
   drawing.fill feature.render_options[:colour]

    if feature.orientation == "forward"
      drawing.polygon(renderer.x, feature.render_options[:top_margin], renderer.x + feature.render_options[:width], renderer.y, renderer.x, feature.render_options[:top_margin] + feature.render_options[:height])
    else
      drawing.polygon(renderer.x, renderer.y, renderer.x + feature.render_options[:width], feature.render_options[:top_margin], renderer.x + feature.render_options[:width], feature.render_options[:top_margin] + feature.render_options[:height])
    end

    drawing.draw(image)

    font_colour = feature.render_options[:font_colour]
    font_size   = feature.render_options[:font_size]

    drawing.annotate(image, feature.render_options[:width], feature.render_options[:top_margin],renderer.x, 0, feature.label) do
      self.fill        = font_colour
      self.gravity     = Magick::CenterGravity
      self.font_weight = Magick::BoldWeight
      self.font_style  = Magick::ItalicStyle
      self.pointsize   = font_size
    end

    return image

  end

end