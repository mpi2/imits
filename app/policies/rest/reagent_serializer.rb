# encoding: utf-8

class Rest::ReagentSerializer
  include Serializable

  JSON_ATTRIBUTES = %w{
    id
    reagent_name
    concentration
  }


  def initialize(reagent, options = {})
    @options = options
    @reagent = reagent
  end

  def as_json
    json_hash = super(@reagent, @options)
    return json_hash
  end
end
