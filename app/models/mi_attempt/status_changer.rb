# encoding: utf-8

module MiAttempt::StatusChanger

  def change_status
    if status_stamps.empty?
      add_status_stamp MiAttemptStatus.micro_injection_in_progress
    elsif status == MiAttemptStatus.micro_injection_aborted.description and
              is_active?
      add_status_stamp MiAttemptStatus.micro_injection_in_progress
    end

    if production_centre_name == 'WTSI'
      if ! is_active?
        add_status_stamp MiAttemptStatus.micro_injection_aborted
      elsif is_released_from_genotyping?
        add_status_stamp MiAttemptStatus.genotype_confirmed
      end
    else
      if ! is_active?
        add_status_stamp MiAttemptStatus.micro_injection_aborted
      elsif number_of_het_offspring.to_i != 0 or number_of_chimeras_with_glt_from_genotyping.to_i != 0
        add_status_stamp MiAttemptStatus.genotype_confirmed
      end
    end

    return true
  end

end
