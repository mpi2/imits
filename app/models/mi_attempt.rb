class MiAttempt < ActiveRecord::Base
  belongs_to :clone
  validates :clone, :presence => true

  belongs_to :mi_attempt_status
  validates :mi_attempt_status, :presence => true

  belongs_to :centre
  belongs_to :distribution_centre, :class_name => 'Centre'

  after_initialize :defaults

  protected

  def defaults
    self.mi_attempt_status = MiAttemptStatus.in_progress
  end
end
