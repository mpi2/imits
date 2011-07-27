# encoding: utf-8

class MiPlanPriority < ActiveRecord::Base
  has_many :mi_plans
  validates :name, :presence => true, :uniqueness => true
end

# == Schema Information
# Schema version: 20110727110911
#
# Table name: mi_plan_priorities
#
#  id          :integer         not null, primary key
#  name        :string(10)      not null
#  description :string(100)
#  created_at  :datetime
#  updated_at  :datetime
#

