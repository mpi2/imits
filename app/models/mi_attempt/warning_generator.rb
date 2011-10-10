# encoding: utf-8

module MiAttempt::WarningGenerator

  WARNING_MESSAGES = {
    :micro_injecting_unassigned_gene => 'The gene being micro-injected has not been assigned to %{production_centre_name} yet - continuing will assign it to %{production_centre_name}.',
    :gene_already_micro_injected => 'This gene has already been micro-injected by another production centre.',
    :assigning_production_centre => 'The consortium %{consortium_name} is planning on micro-injecting this gene, but has not yet assigned a production centre.  Continuing will assign %{production_centre_name} as the ones micro-injecting the gene on behalf of %{consortium_name}.',
    :no_interest_expressed_in_gene => 'There are no expressions of interest for this gene yet.  Continuing will assign %{production_centre_name} to micro-inject it.'
  }

  def generate_warnings
    raise "Cannot generate warnings on non-valid object" unless valid?

    @warnings = []

    return false unless new_record?

    if MiAttempt.public_search(:es_cell_marker_symbol_eq => gene.marker_symbol).result.count != 0
      add_warning :gene_already_micro_injected
      return true
    end

    potential_mi_plan = MiPlan.where(mi_plan_lookup_conditions).first
    if !potential_mi_plan
      add_warning :no_interest_expressed_in_gene
      return true
    end

    if potential_mi_plan.mi_plan_status != MiPlanStatus[:Assigned]
      add_warning :micro_injecting_unassigned_gene
      return true
    end

    return false
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
