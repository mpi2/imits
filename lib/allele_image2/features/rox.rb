class AlleleImage2::Features::Rox < AlleleImage2::Features::DefaultFeature

  # From RMagick docs
  # drawing.polygon(x1, y1,...,xN, yN)
  # drawing.annotate(img, width, height, x, y, text)

  def detailed(renderer, image)

    # Draw the triangle
    drawing = Magick::Draw.new

    drawing.stroke @render_options[:stroke]
    drawing.fill @render_options[:colour]

    if feature.orientation == "forward"
      drawing.polygon(renderer.x, @render_options[:top_margin], renderer.x + @render_options[:width], renderer.y, renderer.x, @render_options[:top_margin] + @render_options[:height])
    else
      drawing.polygon(renderer.x, renderer.y, renderer.x + @render_options[:width], @render_options[:top_margin], renderer.x + @render_options[:width], @render_options[:top_margin] + @render_options[:height])
    end

    drawing.draw(image)

    font_colour = @render_options[:font_colour]
    font_size   = @render_options[:font_size]

    drawing.annotate(image, @render_options[:width], @render_options[:top_margin], renderer.x, 0, feature.label) do
      self.fill        = font_colour
      self.gravity     = Magick::CenterGravity
      self.font_weight = Magick::BoldWeight
      self.font_style  = Magick::ItalicStyle
      self.pointsize   = font_size
    end

    return image

  end

end