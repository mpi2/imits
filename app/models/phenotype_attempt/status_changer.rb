# encoding: utf-8

module PhenotypeAttempt::StatusChanger
  def change_status
    if rederivation_started?
      self.status = PhenotypeAttempt::Status['Rederivation Started']
    else
      self.status = PhenotypeAttempt::Status['Registered']
    end
  end
end
