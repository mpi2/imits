class Pipeline < ActiveRecord::Base
  validates :name       , :presence => true, :uniqueness => true
end

# == Schema Information
# Schema version: 20110421150000
#
# Table name: pipelines
#
#  id          :integer         not null, primary key
#  name        :text            not null
#  description :text
#  created_at  :datetime
#  updated_at  :datetime
#
# Indexes
#
#  index_pipelines_on_name  (name) UNIQUE
#

