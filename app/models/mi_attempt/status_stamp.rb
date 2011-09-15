class MiAttempt::StatusStamp < ActiveRecord::Base
  belongs_to :mi_attempt
  belongs_to :mi_attempt_status
end

# == Schema Information
# Schema version: 20110915000000
#
# Table name: mi_attempt_status_stamps
#
#  id                   :integer         not null, primary key
#  mi_attempt_id        :integer         not null
#  mi_attempt_status_id :integer         not null
#  created_at           :datetime
#  updated_at           :datetime
#
# Indexes
#
#  index_mi_attempt_status_stamp_on_ids  (mi_attempt_id,mi_attempt_status_id) UNIQUE
#

