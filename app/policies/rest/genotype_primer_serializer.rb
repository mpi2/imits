# encoding: utf-8

class Rest::GenotypePrimerSerializer
  include Serializable

  JSON_ATTRIBUTES = %w{
    id
    mutagensis_factor_id
    sequence
    name
    genomic_start_coordinate
    genomic_end_coordinate
  }


  def initialize(genotype_primer, options = {})
    @options = options
    @genotype_primer = genotype_primer
  end

  def as_json
    json_hash = super(@genotype_primer, @options)

    return json_hash
  end

end
