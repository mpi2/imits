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
  after_create :set_cassette_transmission_verified
  after_destroy :set_cassette_transmission_verified

  def make_mi_date_and_in_progress_status_consistent

    if self.status_id == 1
      mi_attempt = self.mi_attempt
      if mi_attempt
        self.created_at = mi_attempt.mi_date.to_datetime
      end
    end
  end
  protected :make_mi_date_and_in_progress_status_consistent

  def set_cassette_transmission_verified
    if self.status_id == 2 # genotype_confirmed
      mi_attempt = MiAttempt.find(self.mi_attempt.id)
      if mi_attempt.cassette_transmission_verified_auto_complete == true
        #genotype_confirmed status stamp destroyed
        mi_attempt = MiAttempt.find(self.mi_attempt.id)
        mi_attempt.cassette_transmission_verified = nil
        mi_attempt.cassette_transmission_verified_auto_complete = false
        mi_attempt.save
      elsif mi_attempt.cassette_transmission_verified.blank?
        mi_attempt.cassette_transmission_verified = self.created_at
        mi_attempt.cassette_transmission_verified_auto_complete = true
        mi_attempt.save
        #genotype_confirmed status stamp created
      end
    end
    true
  end
  protected :set_cassette_transmission_verified
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

