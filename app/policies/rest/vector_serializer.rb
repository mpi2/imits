# encoding: utf-8

class Rest::VectorSerializer
  include Serializable

  JSON_ATTRIBUTES = %w{
    mutagenesis_factor_id
    vector_name
    concentration
    preparation
  }


  def initialize(vector)
    @vector = vector
  end

  def as_json
    json_hash = super(@vector)
    return json_hash
  end
end

# COMPLETE
# FULL_ACCESS_ATTRIBUTES = %w{
#    name
#    contact_name
#    contact_email
#  }
#
#  READABLE_ATTRIBUTES = %w{
#    id
#    code
#    superscript
#  } 