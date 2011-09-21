class MiAttempt::StatusStamp < ActiveRecord::Base
  acts_as_audited
  acts_as_reportable

  belongs_to :mi_attempt
  belongs_to :mi_attempt_status

  delegate :description, :to => :mi_attempt_status
end

# == Schema Information
# Schema version: 20110921000001
#
# Table name: mi_attempt_status_stamps
#
#  id                   :integer         not null, primary key
#  mi_attempt_id        :integer         not null
#  mi_attempt_status_id :integer         not null
#  created_at           :datetime
#  updated_at           :datetime
#

