class Centre < ActiveRecord::Base
  validates :name, :presence => true, :uniqueness => true
end

# == Schema Information
# Schema version: 20110421150000
#
# Table name: centres
#
#  id         :integer         not null, primary key
#  name       :text            not null
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  index_centres_on_name  (name) UNIQUE
#

