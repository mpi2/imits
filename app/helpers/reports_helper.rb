module ReportsHelper

  def conflict_text(mi_plan)
    mi_plans = @mi_plans.select{|plan| plan.id != mi_plan.id && plan.gene_id == mi_plan.gene_id}
    "Other MI plans for: #{mi_plans.map {|plan| plan.consortium.name}.join(', ')}" unless mi_plans.empty?
  end

end