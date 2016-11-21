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


  def initialize(mutagenesis_factor)
    @mutagenesis_factor = mutagenesis_factor

    @crisprs = mutagenesis_factor.crisprs
    @vectors = mutagenesis_factor.vectors
    @genotype_primers = mutagenesis_factor.genotype_primers
  end

  def as_json
    json_hash = super(@mutagenesis_factor)
    json_hash['crisprs_attributes'] = crisprs_attributes
    json_hash['vectors_attributes'] = vectors_attributes
    json_hash['genotype_primers_attributes'] = genotype_primers_attributes

    return json_hash
  end


  def crisprs_attributes
    crisprs_hash = []
    @crisprs.each do |crispr|
      crisprs_hash << Rest::CrisprAttributeSerializer.new(crispr).as_json
    end

    return crisprs_hash
  end

  def vectors_attributes
    vectors_hash = []
    @vectors.each do |vector|
      vectors_hash << Rest::VectorAttributeSerializer.new(vector).as_json
    end

    return distribution_centres_hash
  end

  def genotype_primers_attributes
    genotype_primers_hash = []
    @genotype_primers.each do |genotype_primer|
      genotype_primers_hash << Rest::GenotypePrimerAttributeSerializer.new(genotype_primer).as_json
    end

    return genotype_primers_hash
  end

end


#  FULL_ACCESS_ATTRIBUTES = %w{
#    external_ref
#    individually_set_grna_concentrations
#    guides_generated_in_plasmid
#    grna_concentration
#    no_g0_where_mutation_detected
#    no_nhej_g0_mutants
#    no_deletion_g0_mutants
#    no_hr_g0_mutants
#    no_hdr_g0_mutants
#    no_hdr_g0_mutants_all_donors_inserted
#    no_hdr_g0_mutants_subset_donors_inserted
#    crisprs_attributes
#    vectors_attributes
#    genotype_primers_attributes
#  }
#
#  READABLE_ATTRIBUTES = %w{
#    id
#    private
