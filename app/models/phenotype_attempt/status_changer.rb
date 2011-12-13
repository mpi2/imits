# encoding: utf-8

module PhenotypeAttempt::StatusChanger
  def change_status
    status_name = nil

    if rederivation_started?
      if rederivation_complete?
        if number_of_cre_matings_started > 0
          if number_of_cre_matings_successful > 0
            status_name = 'Cre Excision Complete'
          else
            status_name = 'Cre Excision Started'
          end
        else
          status_name = 'Rederivation Complete'
        end
      else
        status_name = 'Rederivation Started'
      end
    else
      status_name = 'Registered'
    end

    self.status = PhenotypeAttempt::Status[status_name]
  end
end
