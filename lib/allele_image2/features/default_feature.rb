class AlleleImage2::Features::DefaultFeature

  attr_accessor :feature, :simple_image, :render_options

  def initialize(feature, options = {})
    
    @feature = feature

    @text_width = 14

    @render_options = {
      :top_margin => 25,
      :width => feature.label.length * @text_width,
      :height => 40,
      :stroke => 'black',
      :colour => '#fff',
      :stroke_width => 2.5,
      :font_size => 18,
      :font_colour => 'black'
    }.merge(feature.render_options)

  end

  def simplify!
    ## Set this to true if there is a simple image for your feature.
    @simple_image = true
  end

  def width
    @render_options[:width]
  end

  def render(renderer, image)
    return @simple_image ? simple(renderer, image) : detailed(renderer, image)
  end

  # From RMagick docs
  # drawing.rectangle(x1, y1, x2, y2)
  # drawing.annotate(img, width, height, x, y, text)

  def detailed(renderer, image)
    drawing = Magick::Draw.new
    drawing.stroke @render_options[:stroke]
    drawing.fill @render_options[:colour]
    drawing.rectangle(renderer.x, @render_options[:top_margin], renderer.x + @render_options[:width], @render_options[:top_margin] + @render_options[:height])
    drawing.draw(image)

    font_colour = @render_options[:font_colour]
    font_size   = @render_options[:font_size]

    drawing.annotate(image, @render_options[:width], @render_options[:height], renderer.x, @render_options[:top_margin], feature.label) do
      self.fill        = font_colour
      self.font_weight = Magick::BoldWeight
      self.gravity     = Magick::CenterGravity
      self.pointsize   = font_size
    end

  end

  ## No simple image for this feature.
  def simple(renderer, image)
  end

end