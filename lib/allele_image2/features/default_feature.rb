class AlleleImage2::Features::DefaultFeature

  attr_accessor :feature, :simple_image, :render_options

  def initialize(feature, options = {})
    
    @feature = feature

    @text_width = 14
    @exon_min_width = 20 # used in sequence feature, must match to the same var in renederer

    feature.render_options = {
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

  def width
    feature.render_options[:width]
  end

  def render(renderer, image, options = {} )
    return feature.simple ? simple(renderer, image, options ) : detailed(renderer, image, options )
  end

  ## Default detailed image is a rectangular block containing the feature label text
  def detailed(renderer, image, options = {})

    # From RMagick docs
    # drawing.rectangle(x1, y1, x2, y2)
    # drawing.annotate(img, width, height, x, y, text)
    drawing = Magick::Draw.new
    drawing.stroke feature.render_options[:stroke]
    drawing.fill feature.render_options[:colour]
    drawing.rectangle(renderer.x, feature.render_options[:top_margin], renderer.x + feature.render_options[:width], feature.render_options[:top_margin] + feature.render_options[:height])
    drawing.draw(image)

    font_colour = feature.render_options[:font_colour]
    font_size   = feature.render_options[:font_size]

    drawing.annotate(image, feature.render_options[:width], feature.render_options[:height], renderer.x, feature.render_options[:top_margin], feature.label) do
      self.fill        = font_colour
      self.font_weight = Magick::BoldWeight
      self.gravity     = Magick::CenterGravity
      self.pointsize   = font_size
    end

  end

  ## Default simple image for this feature is the same as the detailed one
  def simple(renderer, image, options = {})
    detailed(renderer, image, options)
  end

end