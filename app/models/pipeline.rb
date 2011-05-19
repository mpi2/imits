class Pipeline < ActiveRecord::Base
  validates :name       , :presence => true, :uniqueness => true
end

# == Schema Information
#
# Table name: pipelines
#
#  id          :integer         not null, primary key
#  name        :text            not null
#  description :text
#  created_at  :datetime
#  updated_at  :datetime
#

