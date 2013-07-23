module AlleleImage2
  require "RMagick"

  class Renderer

    attr_accessor :construct, :image_list
    attr_accessor :mutation_type

    def initialize(construct, options = {})
      raise "NotAlleleImageConstruct" unless construct.instance_of?( AlleleImage2::Construct )

      options.reverse_merge!({

      })

      self.construct = construct

    end

  end

end