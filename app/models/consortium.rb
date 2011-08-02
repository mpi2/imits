class Consortium < ActiveRecord::Base
  acts_as_reportable

  validates :name, :presence => true, :uniqueness => true

  has_many :users
  has_many :mi_attempts
end

# == Schema Information
# Schema version: 20110727110911
#
# Table name: consortia
#
#  id         :integer         not null, primary key
#  name       :string(255)     not null
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  index_consortia_on_name  (name) UNIQUE
#

