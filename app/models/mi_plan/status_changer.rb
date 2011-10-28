# encoding: utf-8

module MiPlan::StatusChanger

  def change_status
    if number_of_es_cells_starting_qc != nil
      self.mi_plan_status = MiPlanStatus['Assigned - ES Cell QC In Progress']
    end
  end

end
