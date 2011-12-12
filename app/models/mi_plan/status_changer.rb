# encoding: utf-8

module MiPlan::StatusChanger

  def change_status
    return if self.mi_plan_status == MiPlan::Status['Inactive']

    if number_of_es_cells_passing_qc != nil
      if number_of_es_cells_passing_qc.to_i == 0
        self.mi_plan_status = MiPlan::Status['Aborted - ES Cell QC Failed']
      elsif number_of_es_cells_passing_qc.to_i > 0
        self.mi_plan_status = MiPlan::Status['Assigned - ES Cell QC Complete']
      end
    elsif number_of_es_cells_starting_qc != nil
      self.mi_plan_status = MiPlan::Status['Assigned - ES Cell QC In Progress']
    end
  end

end
