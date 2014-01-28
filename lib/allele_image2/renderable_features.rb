module AlleleImage2

  FUNCTIONAL_UNITS = {

    # TODO remove these 3 eventually
    ["En2 intron", "SA", "En2 exon"] => "En2 SA",
    ["En2 intron", "SA", "En2 exon", "Frame K insert"] => "En2 SA (ATG)",
    ["rat Cd4", "TM domain"] => "Cd4 TM",

    ["mouse En2 intron", "mouse En2 exon"] => "En2 SA",
    ["mouse En2 intron", "Splice Acceptor", "mouse En2 exon"] => "En2 SA",
    ["mouse En2 intron", "Splice Acceptor", "mouse En2 exon", "Frame K insert"] => "En2 SA (ATG)",
    ["rat Cd4", "rat CD4 transmembrane region"] => "Cd4 TM",
    # ["PGK", "DTA", "pA"] => "PGK_DTA_pA",
    # ["pA", "DTA", "PGK"] => "pA_DTA_PGK",
  }

  # SIMPLE_FEATURES = [
  #   'Rox',
  #   'EGFP',
  #   'Cre',
  #   'pu-Delta-tk',
  #   'Frt',
  #   'F3',
  #   'Puro',
  #   'TM-lacZ',
  #   'lacZ',
  #   'loxP',
  #   'Neo',
  #   'NeoR',
  #   'Neo*',
  #   'AttP',
  #   # 'pA',
  #   'SV40 polyadenylation site',
  #   'PolyA',
  #   'sA',
  #   'SA',
  #   'En2 SA',
  #   'Ifitm2 Intron'
  # ]

  # list of cassette features to show in simple images
  # NB. the array element here must match to the 'label' element in the features.yml file
  SIMPLE_FEATURES = [
    'FRT',
    'lacZ',
    'loxP',
    'neo',
    'pA',
    'En2 SA',
    'Rox',
    'EGFP',
    'Cre',
    'Puro',
    'F3',
    'TM-lacZ',
    'AttP',
    'Ifitm2 Intron'
  ]

  SIMPLE_FEATURE_TYPES = %w(promoter)

  class RenderableFeatures

    def self.config
      defined?(RENDERABLE_FEATURES2) ? RENDERABLE_FEATURES2 : load_yaml
    end

    def self.load_yaml
      features = YAML.load_file(File.join(Rails.root, 'lib', 'allele_image2', 'features.yml'))['features']
      return {} if features.blank?

      features.recursively_downcase_keys!
      features.recursively_symbolize_keys!

      features
    end

    attr_accessor :feature_type, :feature_name, :simple

    def initialize(feature_type, feature_name, simple = false)
      @config = self.class.config
      self.feature_type = feature_type
      self.feature_name = feature_name
      self.simple = simple
    end

    def feature_name=(name)
      @feature_name = name.to_s.downcase.to_sym
    end

    def feature_type=(type)
      @feature_type = type.to_s.downcase.to_sym
    end

    def features
      features_hash = @config[@feature_type]
      return {} if features_hash.blank?

      features_hash
    end

    def feature_properties
      if @feature_name.to_s =~ /fragment/

        @feature_properties = features[:fragment]

      else
        @feature_properties = features[@feature_name]
        if @feature_properties && @feature_properties[:alias]
          @feature_properties = features[@feature_properties[:alias].to_sym]
        end
      end

      if @feature_properties.blank?
        @feature_properties = {}
      end

      @feature_properties.reverse_merge!(features[:defaults] || {})

      @feature_properties
    end

    def renderable?
      features.has_key?(@feature_name)
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