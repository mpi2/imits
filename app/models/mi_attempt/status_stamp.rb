# encoding: utf-8

class MiAttempt::StatusStamp < ActiveRecord::Base
  acts_as_audited
  acts_as_reportable

  belongs_to :mi_attempt
  belongs_to :status

  delegate :name, :to => :status
end

# == Schema Information
#
# Table name: mi_attempt_status_stamps
#
#  id            :integer         not null, primary key
#  mi_attempt_id :integer         not null
#  status_id     :integer         not null
#  created_at    :datetime
#  updated_at    :datetime
#

