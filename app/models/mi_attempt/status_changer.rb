# encoding: utf-8

module MiAttempt::StatusChanger

  def change_status
    if self.mi_attempt_status == MiAttemptStatus.micro_injection_aborted and
              self.is_active?
      self.mi_attempt_status = MiAttemptStatus.micro_injection_in_progress
    end

    if self.production_centre_name == 'WTSI'
      if ! self.is_active?
        self.mi_attempt_status = MiAttemptStatus.micro_injection_aborted
      elsif self.is_released_from_genotyping?
        self.mi_attempt_status = MiAttemptStatus.genotype_confirmed
      end
    else
      if ! self.is_active?
        self.mi_attempt_status = MiAttemptStatus.micro_injection_aborted
      elsif self.number_of_het_offspring.to_i != 0 or self.number_of_chimeras_with_glt_from_genotyping.to_i != 0
        self.mi_attempt_status = MiAttemptStatus.genotype_confirmed
      end
    end

    return true
  end

end
