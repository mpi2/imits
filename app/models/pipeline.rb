class Pipeline < ActiveRecord::Base
  validates :name       , :presence => true, :uniqueness => true
  validates :description, :presence => true
end

# == Schema Information
#
# Table name: pipelines
#
#  id          :integer         not null, primary key
#  name        :text            not null
#  description :text            not null
#  created_at  :datetime
#  updated_at  :datetime
#

