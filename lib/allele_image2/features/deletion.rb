class AlleleImage2::Features::Deletion < AlleleImage2::Features::DefaultFeature

  # From RMagick docs
  # drawing.polygon(x1, y1,...,xN, yN)
  # drawing.annotate(img, width, height, x, y, text)

  def detailed(renderer, image, options = {})

    drawing = Magick::Draw.new
    drawing.stroke feature.render_options[:stroke]    
    drawing.fill feature.render_options[:colour]

    drawing.stroke_width( feature.render_options[:stroke_width] )

    # dslash_top_y = feature.render_options[:height] - feature.render_options[:bottom_margin]
    dslash_top_y = feature.render_options[:top_margin]
    dslash_btm_y = feature.render_options[:height] + feature.render_options[:top_margin]
    dslash_width = renderer.x + ( feature.render_options[:text_width] / 2 )

    drawing.line( renderer.x, dslash_top_y, dslash_width, dslash_btm_y )
    drawing.draw( image )
    
    drawing.line( dslash_width, dslash_top_y, renderer.x + feature.render_options[:text_width], dslash_btm_y )
    drawing.draw( image )

    if feature.del_bp && feature.del_exons

      font_colour = feature.render_options[:font_colour]

      del_txt_start_x = renderer.x - 15
      del_txt_start_y = ( feature.render_options[:height] + feature.render_options[:bottom_margin] ) - 8

      del_txt         = feature.del_bp + "\n" + feature.del_exons
      
      drawing.annotate( image, feature.render_options[:width], feature.render_options[:text_height] * 2, del_txt_start_x, del_txt_start_y, del_txt ) do
        self.fill        = font_colour
        self.gravity     = Magick::CenterGravity
        self.font_weight = Magick::BoldWeight
        self.font_style  = Magick::ItalicStyle
        self.pointsize   = 13
      end
    end
  end

  def simple(renderer, image, options = {})

    drawing = Magick::Draw.new
    drawing.stroke feature.render_options[:stroke]    
    drawing.fill feature.render_options[:colour]

    drawing.stroke_width( feature.render_options[:stroke_width] )

    # dslash_top_y = feature.render_options[:height] - feature.render_options[:bottom_margin]
    dslash_top_y = feature.render_options[:top_margin]
    dslash_btm_y = feature.render_options[:height] + feature.render_options[:top_margin]
    dslash_width = renderer.x + ( feature.render_options[:text_width] / 2 )

    drawing.line( renderer.x, dslash_top_y, dslash_width, dslash_btm_y )
    drawing.draw( image )
    
    drawing.line( dslash_width, dslash_top_y, renderer.x + feature.render_options[:text_width], dslash_btm_y )
    drawing.draw( image )
  end

end