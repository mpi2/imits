class AlleleImage2::Features::Asisi < AlleleImage2::Features::DefaultFeature

  # From RMagick docs
  # drawing.line(here_x, here_y, there_x, there_y)

  def detailed(renderer, image)

    drawing = Magick::Draw.new

    annotation_y = renderer.x# - 10 - @render_options[:height]

    # draw the AsiSI on the sequence
    
    drawing.stroke @render_options[:stroke]
    drawing.fill @render_options[:colour]

    font_colour = @render_options[:font_colour]
    font_size   = @render_options[:font_size]

    drawing.annotate(image, @render_options[:width], @render_options[:height], renderer.x, annotation_y, feature.label) do
      self.gravity     = Magick::CenterGravity
      self.font_weight = Magick::BoldWeight
      self.fill        = font_colour
      self.pointsize   = font_size
    end

    # Draw the arrow pointing down in the moddle of the annotation
    draw_arrow(image, [ renderer.x + @render_options[:width] / 2, renderer.y - 2 ], :tail_height => 10, :arm_height => 5, :arm_width => 5)

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
    
    arrow.draw(image)

    return image
  end

end