class AlleleImage2::Features::Ifitm2Intron < AlleleImage2::Features::DefaultFeature

  def detailed(renderer, image, options = {})
    # draw standard boxes with text
    super
  end

  def simple(renderer, image, options = {})

    width         = feature.render_options[:width]
    height        = feature.render_options[:top_margin]
    label         = feature.render_options[:label ] || feature.feature_name
    if label.match(/SD/)
      label = 'SD'
    elsif label.match(/SA/)
      label = 'SA'
    end
    drawing       = Magick::Draw.new
    x             = renderer.x

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