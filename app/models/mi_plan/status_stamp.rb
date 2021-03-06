# encoding: utf-8

class MiPlan::StatusStamp < ActiveRecord::Base
  acts_as_audited
  acts_as_reportable

  belongs_to :mi_plan
  belongs_to :status

  delegate :name, :code, :to => :status
end

# == Schema Information
#
# Table name: mi_plan_status_stamps
#
#  id         :integer          not null, primary key
#  mi_plan_id :integer          not null
#  status_id  :integer          not null
#  created_at :datetime
#  updated_at :datetime
#
# Indexes
#
#  index_one_status_stamp_per_status_and_mi_plan  (status_id,mi_plan_id) UNIQUE
#
