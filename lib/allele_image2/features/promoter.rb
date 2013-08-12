class AlleleImage2::Features::Promoter < AlleleImage2::Features::DefaultFeature

  # From RMagick docs
  # drawing.line(here_x, here_y, there_x, there_y)

  def detailed(renderer, image)

    AlleleImage2::Features::DefaultFeature.new(feature).render(renderer, image)

    # make the dimensions constant
    tail_height = 15
    arm_height  = 5
    arm_width   = 2

    # draw the arrow above the cassette feature
    first_point  = [renderer.x + @render_options[:width] / 2, @render_options[:top_margin]]
    second_point = [renderer.x + @render_options[:width] / 2, @render_options[:top_margin] / 2]
    third_point  = [
      feature.orientation == "forward" ? second_point[0] + tail_height : second_point[0] - tail_height,
      @render_options[:top_margin] / 2
    ]
    arrow_point = [
      third_point[0] + 6,
      third_point[1]
    ]

    drawing      = Magick::Draw.new

    drawing.stroke @render_options[:stroke]
    drawing.fill @render_options[:colour]

    drawing.stroke_width(1)
    drawing.line(first_point[0], first_point[1], second_point[0], second_point[1])
    draw_arrow(
      image, third_point,
      :direction    => feature.orientation == "forward" ? "east" : "west",
      :tail_height  => tail_height,
      :arm_height   => arm_height,
      :arm_width    => arm_width,
      :stroke_width => 1
    )  

    drawing.draw(image)

    return image

  end

  # draw an arrow at the point
  def draw_arrow(image, point, params= {})
    arrow = Magick::Draw.new
    stroke_width = params[:stroke_width] || 2.5

    # set colour and thickness of arrow

    if params[:colour]
      stroke_colour = params[:colour]
    else
      stroke_colour = "black"
    end

    arrow.stroke(stroke_colour)
    arrow.stroke_width(stroke_width)

    # make the value of "point" the center (origin)
    arrow.translate( point.first, point.last )

    # rotate based on the direction
    params[:direction] = params[:direction] || "south"
    case params[:direction]
      when "north" then arrow.rotate(  0)
      when "east"  then arrow.rotate( 90)
      when "south" then arrow.rotate(180)
      when "west"  then arrow.rotate(270)
      else raise "Not a valid direction: #{params[:direction]}"
    end

    # set the arrow dimensions
    params[:tail_height] = params[:tail_height] || 0.100 * image.rows
    params[:arm_height]  = params[:arm_height]  || 0.050 * image.rows
    params[:arm_width]   = params[:arm_width]   || 0.025 * image.columns

    # draw the arrow
    # We are always drawing a south-facing arrow, the "direction"
    # takes care of rotating it to point in the right ... direction
    arrow.line(                   0, params[:tail_height], 0, 0 ) # line going down
    arrow.line(  params[:arm_width],  params[:arm_height], 0, 0 ) # line from the right
    arrow.line( -params[:arm_width],  params[:arm_height], 0, 0 ) # line from the left
    arrow.draw( image )

    return image
  end

end