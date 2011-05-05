class Centre < ActiveRecord::Base
  validates :name, :presence => true, :uniqueness => true
end

# == Schema Information
#
# Table name: centres
#
#  id         :integer         not null, primary key
#  name       :text            not null
#  created_at :datetime
#  updated_at :datetime
#

