class Centre < ActiveRecord::Base
  acts_as_reportable

  validates :name, :presence => true, :uniqueness => true

  has_many :mi_plans

  default_scope :order => 'name ASC'
end

# == Schema Information
#
# Table name: centres
#
#  id         :integer         not null, primary key
#  name       :string(100)     not null
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  index_centres_on_name  (name) UNIQUE
#

