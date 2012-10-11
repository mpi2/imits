# encoding: utf-8

class MiPlan::Status < ActiveRecord::Base
  acts_as_reportable

  include StatusInterface

  validates :name, :presence => true, :uniqueness => true

  def self.all_non_assigned
    return [
      MiPlan::Status['Interest'],
      MiPlan::Status['Conflict'],
      MiPlan::Status['Inspect - GLT Mouse'],
      MiPlan::Status['Inspect - MI Attempt'],
      MiPlan::Status['Inspect - Conflict'],
      MiPlan::Status['Aborted - ES Cell QC Failed'],
      MiPlan::Status['Withdrawn']
    ]
  end

  def self.all_assigned
    return [
      MiPlan::Status['Assigned'],
      MiPlan::Status['Assigned - ES Cell QC In Progress'],
      MiPlan::Status['Assigned - ES Cell QC Complete']
    ]
  end

  def self.all_pre_assignment
    return [
      MiPlan::Status['Conflict'],
      MiPlan::Status['Inspect - GLT Mouse'],
      MiPlan::Status['Inspect - MI Attempt'],
      MiPlan::Status['Inspect - Conflict']
    ]
  end
end

# == Schema Information
#
# Table name: mi_plan_statuses
#
#  id          :integer         not null, primary key
#  name        :string(50)      not null
#  description :string(255)
#  order_by    :integer
#  created_at  :datetime
#  updated_at  :datetime
#  code        :string(10)      not null
#
# Indexes
#
#  index_mi_plan_statuses_on_name  (name) UNIQUE
#

