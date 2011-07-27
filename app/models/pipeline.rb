class Pipeline < ActiveRecord::Base
  acts_as_reportable

  validates :name       , :presence => true, :uniqueness => true
end

# == Schema Information
# Schema version: 20110727110911
#
# Table name: pipelines
#
#  id          :integer         not null, primary key
#  name        :string(50)      not null
#  description :text
#  created_at  :datetime
#  updated_at  :datetime
#
# Indexes
#
#  index_pipelines_on_name  (name) UNIQUE
#

