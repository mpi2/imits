# encoding: utf-8

class Rest::VectorSerializer
  include Serializable

  JSON_ATTRIBUTES = %w{
    id
    mutagenesis_factor_id
    vector_name
    concentration
    preparation
  }


  def initialize(vector, options = {})
    @options = options
    @vector = vector
  end

  def as_json
    json_hash = super(@vector, @options)
    return json_hash
  end
end
