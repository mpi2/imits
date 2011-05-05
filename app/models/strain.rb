class Strain < ActiveRecord::Base
  validates :name, :uniqueness => true, :presence => true
end

# == Schema Information
#
# Table name: strains
#
#  id         :integer         not null, primary key
#  name       :text            not null
#  created_at :datetime
#  updated_at :datetime
#

