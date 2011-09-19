# encoding: utf-8

module MiAttempt::StatusChanger

  def change_status
    status_to_set = nil
    last_status = status_stamps.last.try(:mi_attempt_status)

    if status_stamps.empty?
      status_to_set = MiAttemptStatus.micro_injection_in_progress
    elsif last_status == MiAttemptStatus.micro_injection_aborted and is_active?
      status_to_set = MiAttemptStatus.micro_injection_in_progress
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
      add_status_stamp status_to_set
    end

    return true
  end

end
