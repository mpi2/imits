class Contact < ActiveRecord::Base
  acts_as_audited

  attr_accessible :email

  has_many :notifications, :dependent => :destroy
  has_many :genes, :through => :notifications

  accepts_nested_attributes_for :notifications, :reject_if => :all_blank

  validates :email, :presence => true, :email => true

end

# == Schema Information
#
# Table name: contacts
#
#  id         :integer         not null, primary key
#  email      :string(255)     not null
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  index_contacts_on_email  (email) UNIQUE
#

