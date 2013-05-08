class Strain < ActiveRecord::Base
  acts_as_reportable
  validates :name, :uniqueness => true, :presence => true
end

# == Schema Information
#
# Table name: strains
#
#  id         :integer         not null, primary key
#  name       :string(100)     not null
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  index_strains_on_name  (name) UNIQUE
#

