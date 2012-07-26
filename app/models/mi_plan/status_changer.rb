# encoding: utf-8

module MiPlan::StatusChanger

  ss = ApplicationModel::StatusChangerMachine.new

  ss.add('Assigned') {true}

  ss.add('Assigned - ES Cell QC In Progress') do |plan|
    plan.number_of_es_cells_starting_qc != nil
  end

  ss.add('Assigned - ES Cell QC Complete', 'Assigned - ES Cell QC In Progress') do |plan|
    plan.number_of_es_cells_passing_qc != nil and
            plan.number_of_es_cells_passing_qc > 0
  end

  ss.add('Aborted - ES Cell QC Failed') do |plan|
    plan.number_of_es_cells_passing_qc != nil and
            plan.number_of_es_cells_passing_qc == 0
  end

  ss.add('Withdrawn') { |plan| plan.withdrawn? }

  ss.add('Inactive') { |plan| ! plan.is_active? }

  @@status_changer_machine = ss

  def change_status
    self.status = MiPlan::Status.find_by_name!(@@status_changer_machine.get_status_for(self))
  end

end
