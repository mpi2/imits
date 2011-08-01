namespace :one_time do

  desc 'Back-fill MiPlans from MiAttempt data'
  task :back_fill_mi_plans_from_mi_attempts => :environment do
    MiAttempt.transaction do
      MiAttempt.all.each do |mi_attempt|
        begin
          MiPlan.create!(
            :gene => mi_attempt.es_cell.gene,
            :consortium => mi_attempt.consortium,
            :production_centre => mi_attempt.production_centre,
            :mi_plan_status => MiPlanStatus.find_by_name!('Assigned'),
            :mi_plan_priority => MiPlanPriority.first
          )
        rescue Exception => e
          e2 = RuntimeError.new("(#{e.class.name}): On\n\n#{mi_attempt.to_json}\n\n#{e.message}")
          e2.set_backtrace(e.backtrace)
          raise e2
        end
      end
    end
  end # :back_fill_mi_plans_from_mi_attempts

end
