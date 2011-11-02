# encoding: utf-8

module MiPlan::StatusChanger

  def change_status
    return if self.mi_plan_status == MiPlanStatus['Inactive']

    if number_of_es_cells_passing_qc != nil
      self.mi_plan_status = MiPlanStatus['Assigned - ES Cell QC Complete']
    elsif number_of_es_cells_starting_qc != nil
      self.mi_plan_status = MiPlanStatus['Assigned - ES Cell QC In Progress']
    end
  end

end
