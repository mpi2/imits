# encoding: utf-8

module MiAttempt::WarningGenerator

  WARNING_MESSAGES = {
    :micro_injecting_unassigned_gene => "The gene you are micro-injecting has not been assigned to this production centre",
    :gene_already_micro_injected => "The gene you are micro-injecting has already been micro-injected by another production centre"
  }

  def generate_warnings
    raise "Cannot generate warnings on non-valid object" unless valid?

    @warnings = []

    if new_record? and MiAttempt.public_search(:es_cell_marker_symbol_eq => gene.marker_symbol).result.count != 0
      @warnings.push WARNING_MESSAGES[:gene_already_micro_injected]
    end

    potential_mi_plan = MiPlan.where(mi_plan_lookup_conditions).first
    if potential_mi_plan and potential_mi_plan.mi_plan_status != MiPlanStatus[:Assigned]
        @warnings.push WARNING_MESSAGES[:micro_injecting_unassigned_gene]
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
end
