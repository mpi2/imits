# encoding: utf-8

module MiAttempt::StatusChanger
    
  def change_status
    status_to_set = nil
    last_status = self.mi_attempt_status
    
    if ! last_status
      status_to_set = MiAttemptStatus.micro_injection_in_progress
    elsif last_status == MiAttemptStatus.micro_injection_aborted and self.is_active?
      status_to_set = MiAttemptStatus.micro_injection_in_progress
    end
    
    if total_male_chimeras != nil and total_male_chimeras > 0 and is_active?
        status_to_set = MiAttemptStatus.chimeras_obtained
    end
    
    
    if production_centre_name == 'WTSI'
      if ! is_active?
        status_to_set = MiAttemptStatus.micro_injection_aborted
      elsif is_released_from_genotyping?
        status_to_set = MiAttemptStatus.genotype_confirmed
      end
    else
      if ! is_active?
        status_to_set = MiAttemptStatus.micro_injection_aborted
      elsif number_of_het_offspring.to_i != 0 or number_of_chimeras_with_glt_from_genotyping.to_i != 0
        status_to_set = MiAttemptStatus.genotype_confirmed
      end
    end

    if status_to_set and status_to_set != last_status
      self.mi_attempt_status = status_to_set
    end

    return true
  end

end
