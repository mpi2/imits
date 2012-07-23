# encoding: utf-8

class MiAttempt::StatusStamp < ActiveRecord::Base
  acts_as_audited
  acts_as_reportable

  belongs_to :mi_attempt
  belongs_to :mi_attempt_status, :class_name => 'MiAttempt::Status'

  delegate :name, :to => :mi_attempt_status

  def status; mi_attempt_status; end
end

# == Schema Information
#
# Table name: mi_attempt_status_stamps
#
#  id                   :integer         not null, primary key
#  mi_attempt_id        :integer         not null
#  mi_attempt_status_id :integer         not null
#  created_at           :datetime
#  updated_at           :datetime
#

