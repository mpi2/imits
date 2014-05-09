require 'bio'

module AlleleImage2
  class Parser

    attr_accessor :genbank_data, :genbank, :features, :construct

    def initialize(genbank_data, simple = false)
      @simple = simple
      @genbank_data = genbank_data

      @genbank = Bio::GenBank.new(@genbank_data)

      @alias_hash = {}

      aliases =  AlleleImage2::RenderableFeatures.config[:aliases]

      aliases.each do |key, aliases|
        aliases.each do |a|
          @alias_hash[a.to_sym] = key
        end
      end

      parse
    end

    def parse
      self.features = @genbank.features.map do |f|
        f.feature = @alias_hash[f.feature.downcase.to_sym] || f.feature

        unless f.qualifiers.length == 0
          begin
            new_f = AlleleImage2::Feature.new(f)
            if @simple
              new_f.simplify!
            end
            new_f
          rescue AlleleImage2::Feature::NotRenderableError
          end
        end
      end.compact

      self.features = self.features.sort do |a,b|
        res = a.start <=> b.start
        res = a.stop  <=> b.stop if res == 0
        res
      end

      self.construct = AlleleImage2::Construct.new(
        :features            => self.features.dup,
        :circular            => circular,
        :cassette_label      => extract_label(@genbank, "cassette"),
        :backbone_label      => extract_label(@genbank, "backbone"),
        :bac_label           => extract_label(@genbank, "target_bac"),
        :transcript_id_label => extract_label(@genbank, "transcript_id"),
        :simple              => @simple
      )
    end

    def circular
      @circular ||= @genbank_data.split("\n").first.match(/circular/) ? true : false
    end

    private

      def extract_label(genbank_object, label)
        bioseq = genbank_object.to_biosequence
        return unless bioseq.comments

        result = bioseq.comments.split("\n").find { |x| x.match(label) }
        return unless result

        return result.split(":").last.strip
      end
  end
end