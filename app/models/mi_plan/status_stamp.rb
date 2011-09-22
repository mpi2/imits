# encoding: utf-8

class MiPlan::StatusStamp < ActiveRecord::Base
  belongs_to :mi_plan
  belongs_to :mi_plan_status

  delegate :name, :to => :mi_plan_status
end

# == Schema Information
# Schema version: 20110922000000
#
# Table name: mi_plan_status_stamps
#
#  id                :integer         not null, primary key
#  mi_plan_id        :integer         not null
#  mi_plan_status_id :integer         not null
#  created_at        :datetime
#  updated_at        :datetime
#

