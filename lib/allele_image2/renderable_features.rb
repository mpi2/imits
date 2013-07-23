module AlleleImage2
  class RenderableFeatures

    def self.config
      defined?(RENDERABLE_FEATURES2) ? RENDERABLE_FEATURES2 : load_yaml
    end

    def self.load_yaml
      features = YAML.load_file(File.join(Rails.root, 'lib', 'allele_image2', 'features.yml'))["features"]
      return {} if features.blank?

      features.recursively_symbolize_keys!
      features.recursively_downcase_keys!

      features
    end

    attr_accessor :feature_type, :feature_name, :alias_hash

    def initialize(feature_type, feature_name)
      @config = self.class.config
      self.feature_type = feature_type
      self.feature_name = feature_name

      @alias_hash = {}
      @config[:aliases].each do |key, aliases|
        aliases.each do |a|
          alias_hash[a.to_sym] = key
        end
      end
    end

    def feature_name=(name)
      @feature_name = name.to_s.downcase.to_sym
    end

    def feature_type=(type)
      @feature_type = type.to_s.downcase.to_sym
    end

    def features
      features_hash = @config[@alias_hash[@feature_type] || @feature_type]
      return {} if features_hash.blank?
      features_hash
    end

    def feature_properties
      return features[@feature_name] || features[:defaults]
    end

    def renderable?
      return features.has_key?(@feature_name)
    end

    def self.renderable?(feature_type, feature_name)
      return true if feature_type == 'exon'
      self.new(feature_type, feature_name).renderable?
    end

    def self.feature_properties(feature_type, feature_name)
      self.new(feature_type, feature_name).feature_properties
    end

  end
end