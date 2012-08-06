# encoding: utf-8

module PhenotypeAttempt::StatusManagement

  ss = ApplicationModel::StatusManager.new

  ss.add('Phenotype Attempt Registered') { |pt| true }

  ss.add('Rederivation Started') do |pt|
    pt.rederivation_started?
  end

  ss.add('Rederivation Complete', 'Rederivation Started') do |pt|
    pt.rederivation_complete?
  end

  ss.add('Cre Excision Started') do |pt|
    ! pt.deleter_strain.blank?
  end

  ss.add('Cre Excision Complete', 'Cre Excision Started') do |pt|
    pt.number_of_cre_matings_successful > 0 and (pt.mouse_allele_type == 'b' or pt.mouse_allele_type == '.1')
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

  @@status_manager = ss

  def change_status
    self.status = ::PhenotypeAttempt::Status[@@status_manager.get_status_for(self)]
  end

  def manage_status_stamps
    @@status_manager.manage_status_stamps_for(self)
  end

end
