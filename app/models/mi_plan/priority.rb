# encoding: utf-8

class MiPlan::Priority < ActiveRecord::Base
  acts_as_reportable

  has_many :mi_plans
  validates :name, :presence => true, :uniqueness => true
end

# == Schema Information
#
# Table name: mi_plan_priorities
#
#  id          :integer         not null, primary key
#  name        :string(10)      not null
#  description :string(100)
#  created_at  :datetime
#  updated_at  :datetime
#
# Indexes
#
#  index_mi_plan_priorities_on_name  (name) UNIQUE
#

