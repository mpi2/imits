class AlleleImage2::Features::Sequence < AlleleImage2::Features::DefaultFeature

  # From RMagick docs
  # drawing.line(here_x, here_y, there_x, there_y)

  def detailed(renderer, image, options = {})
    drawing = Magick::Draw.new

    # todo: remove 
    # drawing.stroke @render_options[:stroke]
    # drawing.stroke_width(renderer.options[:sequence_stroke_width])

    # bottom_margin = renderer.y + (@render_options[:height] / 2)

    # here_x = renderer.x
    # here_y = bottom_margin
    # there_x = renderer.x + @text_width / 2
    # there_y = @render_options[:top_margin]

    # drawing.line(here_x, here_y, there_x, there_y)
    # drawing.draw(image)
    # drawing.line(here_x + 8, here_y, there_x + 8, there_y)
    # drawing.draw(image)

    first_dot_x   = renderer.x
    second_dot_x  = renderer.x + @text_width / 2
    third_dot_x   = renderer.x + @text_width

    y_position    = @render_options[:top_margin] + @render_options[:height] - 1

    drawing.stroke( "black" )
    drawing.stroke_width(renderer.options[:sequence_stroke_width])
    drawing.line( first_dot_x,  y_position, first_dot_x  + 2, y_position)
    drawing.draw( image )
    drawing.line( second_dot_x, y_position, second_dot_x + 2, y_position)
    drawing.draw( image )
    drawing.line( third_dot_x,  y_position, third_dot_x  + 2, y_position)
    drawing.draw( image )

    y_position = @render_options[:top_margin] + 1

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

  def simple(renderer, image, options = {})
    drawing       = Magick::Draw.new

    # todo: if using dots in detailed image remove duplicated code here

    first_dot_x   = renderer.x
    second_dot_x  = renderer.x + @text_width / 2
    third_dot_x   = renderer.x + @text_width

    y_position    = @render_options[:top_margin] + @render_options[:height] - 1

    drawing.stroke( "black" )
    drawing.stroke_width(renderer.options[:sequence_stroke_width])
    drawing.line( first_dot_x,  y_position, first_dot_x  + 2, y_position)
    drawing.draw( image )
    drawing.line( second_dot_x, y_position, second_dot_x + 2, y_position)
    drawing.draw( image )
    drawing.line( third_dot_x,  y_position, third_dot_x  + 2, y_position)
    drawing.draw( image )

    y_position = @render_options[:top_margin] + 1

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