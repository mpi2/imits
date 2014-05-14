class AlleleImage2::Features::Exon < AlleleImage2::Features::DefaultFeature

  # From RMagick docs
  # drawing.rectangle(x1, y1, x2, y2) 

  def detailed(renderer, image, options = {})

    drawing = Magick::Draw.new
    drawing.stroke feature.render_options[:stroke]    
    drawing.fill feature.render_options[:colour]

    x1 = renderer.x + ( feature.render_options[:width] - feature.render_options[:exon_rectangle_width] ) / 2
    y1 = feature.render_options[:top_margin]
    x2 = x1 + feature.render_options[:exon_rectangle_width]
    y2 = (feature.render_options[:height] / 2) + renderer.y

    drawing.rectangle(x1, y1, x2, y2)
    drawing.draw(image)

    # if this exon has a rank number, display it
    if feature.exon_rank

      font_colour = feature.render_options[:font_colour]
      font_size   = feature.render_options[:font_size]

      exon_rank_start_x     = renderer.x

      # write the annotation above
      drawing.annotate(image, feature.render_options[:width], feature.render_options[:top_margin], exon_rank_start_x, 0, feature.exon_rank) do
        self.fill        = font_colour
        self.gravity     = Magick::CenterGravity
        self.font_weight = Magick::BoldWeight
        self.font_style  = Magick::ItalicStyle
        self.pointsize   = font_size
      end

    end

    return image
  end

end