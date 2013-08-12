class AlleleImage2::Features::Exon < AlleleImage2::Features::DefaultFeature

  # From RMagick docs
  # drawing.rectangle(x1, y1, x2, y2) 

  def detailed(renderer, image)

    drawing = Magick::Draw.new
    drawing.stroke @render_options[:stroke]
    drawing.fill @render_options[:colour]

    x1 = renderer.x
    y1 = @render_options[:top_margin]
    x2 = x1 + @render_options[:width]
    y2 = (@render_options[:height] / 2) + renderer.y

    drawing.rectangle(x1, y1, x2, y2)
    drawing.draw(image)

    return image
  end

end