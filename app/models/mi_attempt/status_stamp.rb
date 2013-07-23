# encoding: utf-8

class MiAttempt::StatusStamp < ActiveRecord::Base
  acts_as_audited
  acts_as_reportable

  belongs_to :mi_attempt
  belongs_to :status

  delegate :name, :code, :to => :status

  validates :mi_attempt_id, :presence => true
  validates :status_id, :presence => true

  before_save :make_mi_date_and_in_progress_status_consistent

  def make_mi_date_and_in_progress_status_consistent

    if self.status_id == 1
      mi_attempt = self.mi_attempt
      if mi_attempt
        self.created_at = mi_attempt.mi_date.to_datetime
      end
    end
  end
  protected :make_mi_date_and_in_progress_status_consistent

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
# Indexes
#
#  index_one_status_stamp_per_status_and_mi_attempt  (status_id,mi_attempt_id) UNIQUE
#

