class Consortium < ActiveRecord::Base
  validates_presence_of :name
  validates_uniqueness_of :name

  has_many :users
  has_many :mi_attempts
end

# == Schema Information
# Schema version: 20110725165610
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

