# encoding: utf-8

module PhenotypeAttempt::StatusChanger

  @@status_changer_machine = ApplicationModel::StatusChangerMachine.new do |sc|
    sc.add('Phenotype Attempt Registered') { |pt| true }

    sc.add('Rederivation Started') do |pt|
      pt.rederivation_started?
    end

    sc.add('Rederivation Complete', 'Rederivation Started') do |pt|
      pt.rederivation_complete?
    end

    sc.add('Cre Excision Started') do |pt|
      pt.number_of_cre_matings_started > 0
    end

    sc.add('Cre Excision Complete', 'Cre Excision Started') do |pt|
      pt.number_of_cre_matings_successful > 0 and pt.mouse_allele_type == 'b'
    end

    sc.add('Phenotyping Started', 'Cre Excision Complete') do |pt|
      pt.phenotyping_started?
    end

    sc.add('Phenotyping Complete', 'Phenotyping Started') do |pt|
      pt.phenotyping_complete?
    end

    sc.add('Phenotype Attempt Aborted') do |pt|
      ! pt.is_active?
    end
  end

  def change_status
    self.status = PhenotypeAttempt::Status[@@status_changer_machine.get_status_for(self)]
  end

end
