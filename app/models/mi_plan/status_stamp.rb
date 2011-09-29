# encoding: utf-8

class MiPlan::StatusStamp < ActiveRecord::Base
  acts_as_reportable

  belongs_to :mi_plan
  belongs_to :mi_plan_status

  delegate :name, :to => :mi_plan_status
end

# == Schema Information
#
# Table name: mi_plan_status_stamps
#
#  id                :integer         not null, primary key
#  mi_plan_id        :integer         not null
#  mi_plan_status_id :integer         not null
#  created_at        :datetime
#  updated_at        :datetime
#

