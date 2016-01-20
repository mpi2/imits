# encoding: utf-8

class PlanIntention::StatusStamp < ActiveRecord::Base
  acts_as_audited
  acts_as_reportable

  belongs_to :plan_intention
  belongs_to :status

end

# == Schema Information
#
# Table name: plan_intention_status_stamps
#
#  id                :integer          not null, primary key
#  plan_intention_id :integer          not null
#  status_id         :integer          not null
#
