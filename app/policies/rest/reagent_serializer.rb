# encoding: utf-8

class Rest::ReagentSerializer
  include Serializable

  JSON_ATTRIBUTES = %w{
    id
    reagent_name
    concentration
  }


  def initialize(reagent)
    @reagent = reagent
  end

  def as_json
    json_hash = super(@reagent)
    return json_hash
  end
end
