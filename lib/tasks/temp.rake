namespace :temp do

  desc 'temp:mi_plans:assign_genes_and_mark_conflicts'
  task 'mi_plans:assign_genes_and_mark_conflicts' => :environment do
    MiPlan.transaction do
      MiPlan.assign_genes_and_mark_conflicts
    end
  end

end
