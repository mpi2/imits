require 'digest/sha1'

class Old::User < Old::ModelBase
  set_table_name 'per_person'

  belongs_to :centre, :class_name => 'Old::Centre'

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


# == Schema Information
# Schema version: 20110421150000
#
# Table name: per_person
#
#  id            :integer(38)     not null, primary key
#  first_name    :string(128)
#  last_name     :string(128)
#  password_hash :string(128)
#  user_name     :string(32)
#  email         :string(1024)
#  address       :string(2048)
#  centre_id     :integer(38)
#  creator_id    :integer(38)
#  created_date  :datetime
#  edited_by     :string(128)
#  edit_date     :datetime
#  check_number  :integer(38)     default(0)
#  active        :boolean(1)
#  hidden        :boolean(1)
#
# Indexes
#
#  per_person_u01  (user_name) UNIQUE
#

