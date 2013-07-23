require 'bio'

module AlleleImage2
  class Parser

    attr_accessor :genbank_data, :genbank, :features

    def initialize(genbank_data)
      @genbank_data = genbank_data
      @genbank = Bio::GenBank.new(@genbank_data)

      @features = @genbank.features.map do |f|
        unless f.qualifiers.length == 0
          begin
            AlleleImage2::Feature.new(f)
          rescue AlleleImage2::Feature::NotRenderableError
          end
        end
      end.compact

      @features = @features.sort do |a,b|
        res = a.start <=> b.start
        res = a.stop  <=> b.stop if res == 0
        res
      end
    end

    def circular
      @circular ||= @genbank_data.split("\n").first.match(/circular/) ? true : false
    end

  end
end