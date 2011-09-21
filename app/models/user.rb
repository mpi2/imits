class User < ActiveRecord::Base
  devise :database_authenticatable, :rememberable, :validatable

  attr_accessible :email, :password, :password_confirmation, :remember_me,
          :production_centre, :production_centre_id

  belongs_to :production_centre, :class_name => 'Centre'

  after_initialize do
    self.remember_me = true
  end
end

# == Schema Information
# Schema version: 20110921000000
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
#
# Indexes
#
#  index_users_on_email  (email) UNIQUE
#

