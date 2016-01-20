# encoding: utf-8

class PlanIntention::Status < ActiveRecord::Base
  acts_as_reportable

  has_many :plan_intentions
  has_many :status_stamps

  include StatusInterface

  validates :name, :presence => true, :uniqueness => true


end

# == Schema Information
#
# Table name: plan_intention_statuses
#
#  id          :integer          not null, primary key
#  name        :string(50)       not null
#  description :string(255)
#  order_by    :integer
#
# Indexes
#
#  index_plan_intention_statuses_on_name  (name) UNIQUE
#
