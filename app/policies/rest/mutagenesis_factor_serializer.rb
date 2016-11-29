# encoding: utf-8

class Rest::MutagenesisFactorSerializer
  include Serializable

  JSON_ATTRIBUTES = %w{
    id
    external_ref
    individually_set_grna_concentrations
    guides_generated_in_plasmid
    grna_concentration
    private
  }


  def initialize(mutagenesis_factor, options = {})
    @options = options
    @mutagenesis_factor = mutagenesis_factor

    @crisprs = mutagenesis_factor.crisprs
    @vectors = mutagenesis_factor.vectors
    @genotype_primers = mutagenesis_factor.genotype_primers
  end

  def as_json
    json_hash = super(@mutagenesis_factor, @options) do |serialized_hash|
      serialized_hash['crisprs_attributes'] = crisprs_attributes
      serialized_hash['vectors_attributes'] = vectors_attributes
      serialized_hash['genotype_primers_attributes'] = genotype_primers_attributes
    end

    return json_hash
  end


  def crisprs_attributes
    crisprs_hash = []
    @crisprs.each do |crispr|
      crisprs_hash << Rest::CrisprSerializer.new(crispr, @options).as_json
    end

    return crisprs_hash
  end

  def vectors_attributes
    vectors_hash = []
    @vectors.each do |vector|
      vectors_hash << Rest::VectorSerializer.new(vector, @options).as_json
    end

    return vectors_hash
  end

  def genotype_primers_attributes
    genotype_primers_hash = []
    @genotype_primers.each do |genotype_primer|
      genotype_primers_hash << Rest::GenotypePrimerSerializer.new(genotype_primer, @options).as_json
    end

    return genotype_primers_hash
  end

end
