class MiPlan::AggregatedView < ::MiPlan
  set_table_name 'aggregated_mi_plans'

  belongs_to :latest_mi_plan_status, :class_name => 'MiPlanStatus'
end
