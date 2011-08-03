# encoding: utf-8

class MiPlanStatus < ActiveRecord::Base
  acts_as_reportable

  has_many :mi_plans
  validates :name, :presence => true, :uniqueness => true
end

# == Schema Information
# Schema version: 20110802094958
#
# Table name: mi_plan_statuses
#
#  id         :integer         not null, primary key
#  name       :string(50)      not null
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  index_mi_plan_statuses_on_name  (name) UNIQUE
#

