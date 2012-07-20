# encoding: utf-8

module MiAttempt::StatusChanger

  ss = ApplicationModel::StatusChangerMachine.new

  ss.add('Micro-injection in progress') { |mi| true }

  ss.add('Chimeras obtained') do |mi|
    mi.total_male_chimeras.to_i > 0
  end

  ss.add('Genotype confirmed', 'Chimeras obtained') do |mi|
    if mi.production_centre_name == 'WTSI'
      mi.is_released_from_genotyping?
    else
      mi.number_of_het_offspring.to_i != 0 or mi.number_of_chimeras_with_glt_from_genotyping.to_i != 0
    end
  end

  ss.add('Micro-injection aborted') do |mi|
    ! mi.is_active?
  end

  @@status_changer_machine = ss

  def change_status
    self.mi_attempt_status = MiAttemptStatus.find_by_name!(@@status_changer_machine.get_status_for(self))
  end

end
