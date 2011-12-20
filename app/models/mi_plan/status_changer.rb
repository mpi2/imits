# encoding: utf-8

module MiPlan::StatusChanger

  def change_status
    return if self.status == MiPlan::Status['Inactive']

    if number_of_es_cells_passing_qc != nil
      if number_of_es_cells_passing_qc.to_i == 0
        self.status = MiPlan::Status['Aborted - ES Cell QC Failed']
      elsif number_of_es_cells_passing_qc.to_i > 0
        self.status = MiPlan::Status['Assigned - ES Cell QC Complete']
      end
    elsif number_of_es_cells_starting_qc != nil
      self.status = MiPlan::Status['Assigned - ES Cell QC In Progress']
    end
  end

end
