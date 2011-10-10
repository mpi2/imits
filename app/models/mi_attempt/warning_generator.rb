# encoding: utf-8

module MiAttempt::WarningGenerator

  WARNING_MESSAGES = {
    :micro_injecting_unassigned_gene => "The gene being micro-injected has not been assigned to %{production_centre_name} - continuing will assign it to %{production_centre_name}",
    :gene_already_micro_injected => "The gene being micro-injected has already been micro-injected by another production centre"
  }

  def generate_warnings
    raise "Cannot generate warnings on non-valid object" unless valid?

    @warnings = []

    if new_record? and MiAttempt.public_search(:es_cell_marker_symbol_eq => gene.marker_symbol).result.count != 0
      add_warning :gene_already_micro_injected
    end

    potential_mi_plan = MiPlan.where(mi_plan_lookup_conditions).first
    if !potential_mi_plan or potential_mi_plan.mi_plan_status != MiPlanStatus[:Assigned]
        add_warning :micro_injecting_unassigned_gene
    end

    return !@warnings.empty?
  end

  def warnings
    if @warnings.blank?
      return nil
    else
      return @warnings
    end
  end

  def add_warning(template)
    @warnings.push(WARNING_MESSAGES[template.to_sym] % self.as_json.symbolize_keys)
  end
  private :add_warning
end
