class AlleleImage2::Features::SpliceAcceptor < AlleleImage2::Features::DefaultFeature

  def detailed(renderer, image, options = {})

    # From RMagick docs
    # drawing.rectangle(x1, y1, x2, y2)
    # drawing.annotate(img, width, height, x, y, text)
    drawing = Magick::Draw.new
    drawing.stroke feature.render_options[:stroke]
    drawing.fill feature.render_options[:colour]
    drawing.rectangle(renderer.x, feature.render_options[:top_margin], renderer.x + feature.render_options[:width], feature.render_options[:top_margin] + feature.render_options[:height])
    drawing.draw(image)

    font_colour = feature.render_options[:font_colour]
    font_size   = feature.render_options[:font_size]

    drawing.annotate(image, feature.render_options[:width], feature.render_options[:height], renderer.x, feature.render_options[:top_margin], feature.label) do
      self.fill        = font_colour
      self.font_weight = Magick::BoldWeight
      self.gravity     = Magick::CenterGravity
      self.pointsize   = font_size
    end

    if feature.feature_name.match(/ATG/)
      # write the annotation above
      pointsize = font_size * 0.75
      atg_label = Magick::Draw.new
      atg_label.annotate( image, feature.render_options[:width], feature.render_options[:top_margin], renderer.x, 0, "ATG" ) do
        self.fill        = "black"
        self.gravity     = Magick::CenterGravity
        self.font_weight = Magick::BoldWeight
        self.font_style  = Magick::ItalicStyle
        self.pointsize   = pointsize
      end
    end
  end

  def simple(renderer, image, options = {})

    width         = feature.render_options[:width]
    height        = feature.render_options[:top_margin]
    label         = feature.render_options[:label ] || feature.feature_name
    drawing       = Magick::Draw.new
    x             = renderer.x

    # write the text under the main image
    y = 68

    font_colour = feature.render_options[:font_colour]
    font_size   = feature.render_options[:font_size]

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