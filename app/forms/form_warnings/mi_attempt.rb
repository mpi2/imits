# encoding: utf-8

module FormWarnings::MiAttempt

  WARNING_MESSAGES = {
    :micro_injecting_unassigned_gene => 'The gene being micro-injected has not been assigned to %{production_centre_name} yet - continuing will assign it to %{production_centre_name}.',
    :gene_already_micro_injected => 'This gene has already been micro-injected by another production centre.',
    :setting_production_centre => 'The consortium %{consortium_name} is planning on micro-injecting this gene, but has not yet assigned a production centre.  Continuing will assign your production centre as the production centre micro-injecting the gene on behalf of %{consortium_name}.',
    :updating_another_production_centre_mi_attempt => 'You are creating an mi_attempt for another production centre. Continuing will create this mi_attempt for %{production_centre_name}'
  }

  def generate_warnings
    raise "Cannot generate warnings on non-valid object" unless valid?

    @warnings = []

    return false unless new_record?

    if MiAttempt.search(:mi_plan_gene_marker_symbol_eq => gene.marker_symbol).result.count != 0
      add_warning :gene_already_micro_injected
      return true
    end

    potential_mi_plan = self.mi_plan
    if potential_mi_plan.production_centre == nil
      add_warning :setting_production_centre
      return true
    end

    if ! potential_mi_plan.assigned?
      add_warning :micro_injecting_unassigned_gene
      return true
    end

    if updated_by and (production_centre_name != updated_by.production_centre_name)
      add_warning :updating_another_production_centre_mi_attempt
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
