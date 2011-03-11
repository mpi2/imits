require 'digest/md5'

class User < ActiveRecord::Base
  set_table_name 'per_person'

  def self.authenticate(username, password)
    password_md5 = Digest::MD5.hexdigest(password)

    user = self.find_by_user_name username
    if user && user.password_hash == password_md5
      return user
    else
      return nil
    end
  end

  def full_name
    return first_name + ' ' + last_name
  end

end
