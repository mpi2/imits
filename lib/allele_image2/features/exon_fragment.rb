class AlleleImage2::Features::ExonFragment < AlleleImage2::Features::DefaultFeature

  # From RMagick docs
  # drawing.rectangle(x1, y1, x2, y2) 
  # drawing.polygon(x1, y1,...,xN, yN)

  def detailed(renderer, image, options = {})

    drawing = Magick::Draw.new
    drawing.stroke feature.render_options[:stroke]
    drawing.fill feature.render_options[:colour]

    bottom_margin = renderer.y + feature.render_options[:height]
    right_edge = 

    # draw an exon rectangle
    x1 = renderer.x + ( feature.render_options[:width] - feature.render_options[:exon_rectangle_width] ) / 2
    y1 = feature.render_options[:top_margin]
    x2 = x1 + feature.render_options[:exon_rectangle_width]
    y2 = (feature.render_options[:height] / 2) + renderer.y

    drawing.rectangle(x1, y1, x2, y2)

    drawing.fill feature.render_options[:secondary_colour]

    # overlay the basic rectangle with a triangle to create the fragment image
    x1 = renderer.x + ( feature.render_options[:width] - feature.render_options[:exon_rectangle_width] ) / 2
    y1 = renderer.y - ( feature.render_options[:height] / 2 )
    x2 = x1
    y2 = renderer.y + (feature.render_options[:height] / 2)
    x3 = x1 + feature.render_options[:exon_rectangle_width]
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

      font_colour = feature.render_options[:font_colour]
      font_size   = feature.render_options[:font_size]

      # write the annotation above
      drawing.annotate(image, feature.render_options[:width], feature.render_options[:top_margin], renderer.x, 0, feature.exon_rank) do
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