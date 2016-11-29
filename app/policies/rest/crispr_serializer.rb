# encoding: utf-8

class Rest::CrisprSerializer
  include Serializable

  JSON_ATTRIBUTES = %w{
    id
    mutagensis_factor_id
    sequence
    chr
    start
    end
    grna_concentration
    individually_set_grna_concentrations
    guides_generated_in_plasmid
  }


  def initialize(crispr, options = {})
    @options = options
    @crispr = crispr
  end

  def as_json
    json_hash = super(@crispr, @options)
    return json_hash
  end
end
