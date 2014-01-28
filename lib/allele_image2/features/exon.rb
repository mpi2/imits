class AlleleImage2::Features::Exon < AlleleImage2::Features::DefaultFeature

  # From RMagick docs
  # drawing.rectangle(x1, y1, x2, y2) 

  def detailed(renderer, image, options = {})

    drawing = Magick::Draw.new
    drawing.stroke @render_options[:stroke]
    drawing.fill @render_options[:colour]

    x1 = renderer.x
    y1 = @render_options[:top_margin]
    x2 = x1 + @render_options[:width]
    y2 = (@render_options[:height] / 2) + renderer.y

    drawing.rectangle(x1, y1, x2, y2)
    drawing.draw(image)

    # if this exon has a rank number, display it
    if feature.exon_rank

      font_colour = @render_options[:font_colour]
      font_size   = @render_options[:font_size]

      # write the annotation above
      drawing.annotate(image, @render_options[:width], @render_options[:top_margin], renderer.x, 0, feature.exon_rank) do
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