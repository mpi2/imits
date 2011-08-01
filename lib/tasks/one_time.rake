namespace :one_time do

  desc 'Back-fill MiPlans from MiAttempt data'
  task :back_fill_mi_plans_from_mi_attempts => :environment do
    MiAttempt.transaction do
      MiAttempt.all.each do |mi_attempt|
        begin
          gene = mi_attempt.es_cell.gene
          consortium = mi_attempt.consortium
          production_centre = mi_attempt.production_centre

          mi_plan = MiPlan.find_by_gene_id_and_consortium_id_and_production_centre_id(
            gene, consortium, production_centre)
          if ! mi_plan
            MiPlan.create!(
              :gene => gene,
              :consortium => consortium,
              :production_centre => production_centre,
              :mi_plan_status => MiPlanStatus.find_by_name!('Assigned'),
              :mi_plan_priority => MiPlanPriority.first
            )
          end
        rescue Exception => e
          e2 = RuntimeError.new("(#{e.class.name}): On\n\n#{mi_attempt.to_json}\n\n#{e.message}")
          e2.set_backtrace(e.backtrace)
          raise e2
        end
      end
    end
  end # :back_fill_mi_plans_from_mi_attempts

end
