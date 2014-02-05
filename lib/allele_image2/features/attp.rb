class AlleleImage2::Features::Attp < AlleleImage2::Features::DefaultFeature

  # From RMagick docs
  # drawing.polygon(x1, y1,...,xN, yN)
  # drawing.annotate(img, width, height,x, y, text)

  def detailed(renderer, image, options = {})

    # Draw the triangle
    drawing = Magick::Draw.new

    drawing.stroke feature.render_options[:stroke]
    drawing.fill feature.render_options[:colour]

    x1 = renderer.x - 2
    y1 = feature.render_options[:top_margin]
    x2 = x1 + feature.render_options[:width]
    y2 = y1
    x3 = x1
    y3 = y1 + feature.render_options[:height]

    bottom_margin = renderer.y - feature.render_options[:height]

    drawing.polygon(x1, y1,x2, y2, x1, y3)
    drawing.draw(image)

    drawing.stroke feature.render_options[:stroke]
    drawing.fill feature.render_options[:colour]

    x4 = renderer.x + 2
    y4 = y3
    x5 = x2 + 2
    y5 = y2 + 2
    x6 = x5
    y6 = feature.render_options[:top_margin] + feature.render_options[:height]

    drawing.polygon(x4, y4, x5, y5, x6, y6)
    drawing.draw(image)

    font_colour = feature.render_options[:font_colour]
    font_size   = feature.render_options[:font_size]

    # write the annotation above
    drawing.annotate(image, feature.render_options[:width], feature.render_options[:top_margin], renderer.x, 0, feature.label) do
      self.fill        = font_colour
      self.gravity     = Magick::CenterGravity
      self.font_weight = Magick::BoldWeight
      self.font_style  = Magick::ItalicStyle
      self.pointsize   = font_size
    end

    return image

  end

end