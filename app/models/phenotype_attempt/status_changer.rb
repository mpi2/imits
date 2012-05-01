# encoding: utf-8

module PhenotypeAttempt::StatusChanger

  ss = ApplicationModel::StatusChangerMachine.new

  ss.add('Phenotype Attempt Registered') { |pt| true }

  ss.add('Rederivation Started') do |pt|
    pt.rederivation_started?
  end

  ss.add('Rederivation Complete', 'Rederivation Started') do |pt|
    pt.rederivation_complete?
  end

  ss.add('Cre Excision Started') do |pt|
    pt.number_of_cre_matings_started > 0
  end

  ss.add('Cre Excision Complete', 'Cre Excision Started') do |pt|
    pt.number_of_cre_matings_successful > 0 and pt.mouse_allele_type == 'b'
  end

  ss.add('Phenotyping Started', 'Cre Excision Complete') do |pt|
    pt.phenotyping_started?
  end

  ss.add('Phenotyping Complete', 'Phenotyping Started') do |pt|
    pt.phenotyping_complete?
  end

  ss.add('Phenotype Attempt Aborted') do |pt|
    ! pt.is_active?
  end

  @@status_changer_machine = ss

  def change_status
    self.status = ::PhenotypeAttempt::Status[@@status_changer_machine.get_status_for(self)]
  end

end
