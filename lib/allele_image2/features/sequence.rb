class AlleleImage2::Features::Sequence < AlleleImage2::Features::DefaultFeature

  # From RMagick docs
  # drawing.line(here_x, here_y, there_x, there_y)

  def detailed(renderer, image, options = {})
    drawing = Magick::Draw.new

    # drawing 3 dots at top and bottom level with exon heights
    first_dot_x   = renderer.x
    second_dot_x  = renderer.x + ( @exon_min_width / 2 )
    third_dot_x   = renderer.x + @exon_min_width
    
    y_position    = feature.render_options[:top_margin] + feature.render_options[:height] - 1

    drawing.stroke( "black" )
    drawing.stroke_width(renderer.options[:sequence_stroke_width])
    drawing.line( first_dot_x,  y_position, first_dot_x  + 2, y_position)
    drawing.draw( image )
    drawing.line( second_dot_x, y_position, second_dot_x + 2, y_position)
    drawing.draw( image )
    drawing.line( third_dot_x,  y_position, third_dot_x  + 2, y_position)
    drawing.draw( image )

    y_position = feature.render_options[:top_margin] + 1

    drawing.stroke( "black" )
    drawing.stroke_width(renderer.options[:sequence_stroke_width])
    drawing.line( first_dot_x,  y_position, first_dot_x  + 2, y_position)
    drawing.draw( image )
    drawing.line( second_dot_x, y_position, second_dot_x + 2, y_position)
    drawing.draw( image )
    drawing.line( third_dot_x,  y_position, third_dot_x  + 2, y_position)
    drawing.draw( image )

    return image
  end

end