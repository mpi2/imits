class Consortium < ActiveRecord::Base
  acts_as_reportable

  validates :name, :presence => true, :uniqueness => true

  has_many :users
  has_many :mi_plans
end

# == Schema Information
# Schema version: 20110922000000
#
# Table name: consortia
#
#  id           :integer         not null, primary key
#  name         :string(255)     not null
#  funding      :string(255)
#  participants :text
#  contact      :string(255)
#  created_at   :datetime
#  updated_at   :datetime
#
# Indexes
#
#  index_consortia_on_name  (name) UNIQUE
#

