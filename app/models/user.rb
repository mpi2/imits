class User < ActiveRecord::Base
  ADMIN_USERS = [
    'aq2@sanger.ac.uk',
    'vvi@sanger.ac.uk',
    're4@sanger.ac.uk',
    'pen1adm@sanger.ac.uk',
    'pen2adm@sanger.ac.uk'
  ]

  REMOTE_ACCESS_USERS = [
    'aq2@sanger.ac.uk',
    'vvi@sanger.ac.uk',
    're4@sanger.ac.uk',
    'a.blake@har.mrc.ac.uk'
  ]

  devise :database_authenticatable, :rememberable, :validatable

  attr_accessible :email, :password, :password_confirmation, :remember_me,
          :production_centre, :production_centre_id, :name, :is_contactable

  belongs_to :production_centre, :class_name => 'Centre'

  after_initialize do
    self.remember_me = true
  end

  def admin?
    return ADMIN_USERS.include?(email)
  end

  def remote_access?
    return REMOTE_ACCESS_USERS.include?(email)
  end

  def can_see_sub_project?
    return ['WTSI','JAX'].include?(production_centre.name)
  end
end

# == Schema Information
#
# Table name: users
#
#  id                   :integer         not null, primary key
#  email                :string(255)     default(""), not null
#  encrypted_password   :string(128)     default(""), not null
#  remember_created_at  :datetime
#  production_centre_id :integer         not null
#  created_at           :datetime
#  updated_at           :datetime
#  name                 :string(255)
#  is_contactable       :boolean         default(FALSE)
#
# Indexes
#
#  index_users_on_email  (email) UNIQUE
#
