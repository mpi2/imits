namespace :one_time do

  desc 'Back-fill MiPlans from MiAttempt data'
  task :back_fill_mi_plans_from_mi_attempts => :environment do
    MiAttempt.transaction do
      MiAttempt.all.each do |mi_attempt|
        if mi_attempt.production_centre.name == 'WTSI'
          if mi_attempt.es_cell.pipeline.name == 'EUCOMM'
            consortium = Consortium.find_by_name!('EUCOMM-EUMODIC')
          else
            consortium = Consortium.find_by_name!('MGP')
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
  end # :back_fill_mi_plans_from_mi_attempts

end
