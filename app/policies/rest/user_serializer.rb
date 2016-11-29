# encoding: utf-8

class Rest::UserSerializer
  include Serializable

  JSON_ATTRIBUTES = %w{
    name
    email
    remember_me
    production_centre
    production_centre_id
    is_contactable
  }


  def initialize(user, options = {})
    @options = options
    @user = user
  end

  def as_json
    json_hash = super(@user, @options)
    return json_hash
  end
end
