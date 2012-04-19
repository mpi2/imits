class Contact < ActiveRecord::Base
  attr_accessible :email

  has_many :notifications
  has_many :genes, :through => :notifications

  accepts_nested_attributes_for :notifications, :reject_if => :all_blank
  
  validates :email, :presence => true, :email => true
  
end

# == Schema Information
#
# Table name: contacts
#
#  id           :integer         not null, primary key
#  email        :string(255)     not null
#  first_name   :string(255)
#  last_name    :string(255)
#  institution  :string(255)
#  organisation :string(255)
#  created_at   :datetime
#  updated_at   :datetime
#
# Indexes
#
#  index_contacts_on_email  (email) UNIQUE
#

