require 'digest/md5'

class Person < ActiveRecord::Base
  set_table_name 'per_person'

  def self.authenticate(username, password)
    password_md5 = Digest::MD5.hexdigest(password)

    person = Person.find_by_user_name username
    if person && person.password_hash == password_md5
      return person
    else
      return nil
    end
  end

end
