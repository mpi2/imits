class AlleleImage2::Features::ExonFragment < AlleleImage2::Features::DefaultFeature

  # From RMagick docs
  # drawing.rectangle(x1, y1, x2, y2) 
  # drawing.polygon(x1, y1,...,xN, yN)

  def detailed(renderer, image)

    drawing = Magick::Draw.new
    drawing.stroke @render_options[:stroke]
    drawing.fill @render_options[:colour]

    bottom_margin = renderer.y + @render_options[:height]
    right_edge = 


    x1 = renderer.x
    y1 = @render_options[:top_margin]
    x2 = x1 + @render_options[:width]
    y2 = (@render_options[:height] / 2) + renderer.y

    drawing.rectangle(x1, y1, x2, y2)

    drawing.fill @render_options[:secondary_colour]

    x1 = renderer.x#renderer.x
    y1 = renderer.y - (@render_options[:height] / 2)
    x2 = renderer.x
    y2 = renderer.y + (@render_options[:height] / 2)
    x3 = renderer.x + @render_options[:width]
    y3 = y2
    x4 = x1
    y4 = y1

    drawing.polygon(x1, y1,
              x2, y2,
              x3, y3,
              x4, y4)

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