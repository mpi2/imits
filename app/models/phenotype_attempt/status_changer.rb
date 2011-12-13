# encoding: utf-8

module PhenotypeAttempt::StatusChanger
  def change_status
    if rederivation_started?
      if rederivation_completed?
        self.status = PhenotypeAttempt::Status['Rederivation Completed']
      else rederivation_started?
        self.status = PhenotypeAttempt::Status['Rederivation Started']
      end
    else
      self.status = PhenotypeAttempt::Status['Registered']
    end
  end
end
