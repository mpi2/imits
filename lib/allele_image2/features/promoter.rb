class AlleleImage2::Features::Promoter < AlleleImage2::Features::DefaultFeature

  # From RMagick docs
  # drawing.line(here_x, here_y, there_x, there_y)

   def detailed(renderer, image, options = {})

    AlleleImage2::Features::DefaultFeature.new(feature).render(renderer, image)

    # make the dimensions constant
    tail_height = 15
    arm_height  = 5
    arm_width   = 2

    # draw the arrow above the cassette feature
    first_point  = [renderer.x + feature.render_options[:width] / 2, feature.render_options[:top_margin]]
    second_point = [renderer.x + feature.render_options[:width] / 2, feature.render_options[:top_margin] / 2]
    third_point  = [
      feature.orientation == "forward" ? second_point[0] + tail_height : second_point[0] - tail_height,
      feature.render_options[:top_margin] / 2
    ]
    arrow_point = [
      third_point[0] + 6,
      third_point[1]
    ]

    drawing      = Magick::Draw.new

    drawing.stroke feature.render_options[:stroke]
    drawing.fill feature.render_options[:colour]

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

  def simple(renderer, image, options = {})

    # make the dimensions constant
    tail_height  = 15
    arm_height   = 9
    arm_width    = 6
    line_width   = 6

    arrow_xlocn = renderer.x - 15

    # fetch attached antibiotic feature if present
    if options[:related_feature]
      antibiotic_resistance_feature = options[:related_feature]
      ab_render_options = antibiotic_resistance_feature.render_options[:simple]
    end

    if antibiotic_resistance_feature && antibiotic_resistance_feature.image.width
      related_image_width = antibiotic_resistance_feature.image.width
    else
      related_image_width = feature.render_options[:width]
    end

    # draw the arrow above the related cassette feature
    first_point  = [ arrow_xlocn + related_image_width / 2, feature.render_options[:top_margin]     ]
    second_point = [ arrow_xlocn + related_image_width / 2, feature.render_options[:top_margin] / 2 ]
    third_point  = [
      feature.orientation == "forward" ? second_point[0] + tail_height : second_point[0] - tail_height,
      feature.render_options[:top_margin] / 2
    ]
    arrow_point  = [
      third_point[0] + arm_width,
      third_point[1]
    ]
    
    # fetch colours from attached antibiotic feature
    if ab_render_options && ab_render_options[:colour]
      arrow_colour = ab_render_options[:colour]
    end

    unless arrow_colour
      arrow_colour = 'black'
    end
    
    drawing              = Magick::Draw.new

    # drawing a bezier curve and displaying the border line
    drawing.stroke       = arrow_colour
    drawing.stroke_width = line_width
    drawing.fill_opacity(0)
    drawing.bezier(first_point[0],first_point[1], first_point[0], third_point[1], first_point[0], third_point[1], third_point[0], third_point[1])

    draw_arrow(
      image, arrow_point,
      :direction    => feature.orientation == "forward" ? "east" : "west",
      :tail_height  => tail_height,
      :arm_height   => arm_height,
      :arm_width    => arm_width,
      :colour       => arrow_colour
    )

    drawing.draw( image )

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