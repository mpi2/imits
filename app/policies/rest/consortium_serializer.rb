# encoding: utf-8

class Rest::ConsortiumSerializer
  include Serializable

  JSON_ATTRIBUTES = %w{
    id
    name
    funding
    participants
    contact
  }


  def initialize(consortium)
    @consortium = consortium
  end

  def as_json
    json_hash = super(@consortium)
    return json_hash
  end
end

# COMPLETE
#  READABLE_ATTRIBUTES = %w{
#    id
#    name
#    funding
#    participants
#    contact
#  }
