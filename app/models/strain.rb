class Strain < ActiveRecord::Base
  validates :name, :uniqueness => true, :presence => true
end

# == Schema Information
# Schema version: 20110922000000
#
# Table name: strains
#
#  id         :integer         not null, primary key
#  name       :string(50)      not null
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  index_strains_on_name  (name) UNIQUE
#

