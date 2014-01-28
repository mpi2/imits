class AlleleImage2::Features::En2SA < AlleleImage2::Features::DefaultFeature

  # From RMagick docs
  # drawing.polygon(x1, y1,...,xN, yN)
  # drawing.annotate(img, width, height, x, y, text)

  def detailed(renderer, image, options = {})
    # draw standard boxes with text
    super
  end

  def simple(renderer, image, options = {})

    width         = @render_options[:width]
    height        = @render_options[:top_margin]
    label         = @render_options[:label ] || feature.feature_name
    drawing       = Magick::Draw.new
    x             = renderer.x

    y = 68

    font_colour = @render_options[:font_colour]
    font_size   = @render_options[:font_size]

    # annotate the block
    drawing.annotate( image, width, height, x, y, label ) do
      self.fill        = font_colour
      self.font_weight = Magick::BoldWeight
      self.gravity     = Magick::CenterGravity
      self.pointsize   = font_size
      self.font_style  = Magick::ItalicStyle
    end

    return image
  end

end