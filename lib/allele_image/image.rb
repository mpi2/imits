module AlleleImage
  class Image
    attr_reader :construct, :input, :parser, :renderer

    def initialize(input, options = {})
      @input         = input
      @parser        = AlleleImage::Parser.new(@input, options[:simple])
      @construct     = @parser.construct
      
      @renderer      = AlleleImage::Renderer.new(@construct, :cassetteonly => options[:cassetteonly], :mutation_type => options[:mutation_type])
    end

    def render
      @renderer.image
    end
  end
end
