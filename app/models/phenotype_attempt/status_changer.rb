# encoding: utf-8

module PhenotypeAttempt::StatusChanger
  def change_status
    self.status = PhenotypeAttempt::Status['Registered']
  end
end
