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


  def initialize(user)
    @user = user
  end

  def as_json
    json_hash = super(@user)
    return json_hash
  end
end

#     :email, :password, :password_confirmation, :remember_me,
#     :production_centre, :production_centre_id, :name, :is_contactable