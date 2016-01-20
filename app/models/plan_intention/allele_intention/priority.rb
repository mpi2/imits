# encoding: utf-8

class PlanIntention::AlleleIntention::Priority < ActiveRecord::Base
  acts_as_reportable

  has_many :plan_intentions
  validates :name, :presence => true, :uniqueness => true
end

# == Schema Information
#
# Table name: plan_intention_allele_intention_priorities
#
#  id          :integer          not null, primary key
#  name        :string(10)       not null
#  description :string(100)
#  created_at  :datetime
#  updated_at  :datetime
#
# Indexes
#
#  index_plan_intention_allele_intention_priorities_on_name  (name) UNIQUE
#
