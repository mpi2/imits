module AlleleImage2
  class Image
    attr_reader :construct, :input, :parser, :renderer

    def initialize(input, options = {})
      @input         = input
      @parser        = AlleleImage2::Parser.new(@input, options[:simple])
      @construct     = @parser.construct
      
      @renderer      = AlleleImage2::Renderer.new(@construct, :cassetteonly => options[:cassetteonly], :mutation_type => options[:mutation_type])
    end

    def render
      @renderer.image
    end
  end
end
