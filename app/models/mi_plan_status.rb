class MiPlanStatus < ActiveRecord::Base
  has_many :mi_plans
  validates :name, :presence => true, :uniqueness => true
end

# == Schema Information
# Schema version: 20110727110911
#
# Table name: mi_plan_statuses
#
#  id         :integer         not null, primary key
#  name       :string(50)      not null
#  created_at :datetime
#  updated_at :datetime
#

