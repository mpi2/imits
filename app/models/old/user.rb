require 'digest/sha1'

class Old::User < Old::ModelBase
  set_table_name 'per_person'

  def self.authenticate(username, password)
    password_sha1 = Digest::SHA1.hexdigest(password)

    user = self.find_by_user_name username
    if user && user.password_hash == password_sha1
      return user
    else
      return nil
    end
  end

  def full_name
    return first_name + ' ' + last_name
  end

end
