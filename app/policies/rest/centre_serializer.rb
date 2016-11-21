# encoding: utf-8

class Rest::CentreSerializer
  include Serializable

  JSON_ATTRIBUTES = %w{
    id
    name
    contact_name
    contact_email
    code
    superscript
  }


  def initialize(centre)
    @centre = centre
  end

  def as_json
    json_hash = super(@centre)
    return json_hash
  end
end
