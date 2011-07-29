namespace :one_time do
  desc 'Back-fill MiPlans from MiAttempt data'
  task :back_fill_mi_plans_from_mi_attempts => :environment do
    MiAttempt.all.each do |mi_attempt|
      if mi_attempt.production_centre.name == 'WTSI'
        if mi_attempt.es_cell.pipeline.name == 'EUCOMM'
          consortium = Consortium.find_by_name!('EUCOMM-EUMODIC')
        elsif mi_attempt.es_cell.pipeline.name == 'KOMP-CSD'
          consortium = Consortium.find_by_name!('MGP')
        else
          raise "Cannot deduce pipeline for mi_attempt(production_centre: #{mi_attempt.production_centre.name}, pipeline: #{mi_attempt.cs_cell.pipeline.name})"
        end
      else
        consortium = Consortium.find_by_name!('EUCOMM-EUMODIC')
      end

      MiPlan.create!(
        :gene => mi_attempt.es_cell.gene,
        :consortium => consortium,
        :production_centre => mi_attempt.production_centre,
        :mi_plan_status => MiPlanStatus.find_by_name!('Assigned'),
        :mi_plan_priority => MiPlanPriority.first
      )
    end
  end
end
