namespace :cron do
  desc 'Clone production DB and reset passwords to "password"'
  task :clone_production_and_reset_passwords => ['db:production:clone', 'db:passwords:reset']

  desc 'MiPlan - Run the gene assignment/conflict resolution logic'
  task :assign_genes_and_mark_conflicts => [:environment] do
    MiPlan.transaction { MiPlan.assign_genes_and_mark_conflicts }
  end

  desc 'MiPlan - Mark old unsuccessful MiPlans as "Inactive"'
  task :mark_old_plans_as_inactive => [:environment] do
    MiPlan.transaction { MiPlan.mark_old_plans_as_inactive }
  end

  desc 'Gene/EsCell - Sync data caches with BioMarts and remote data sources'
  task :sync_data_with_remotes => [:environment] do
    Gene.transaction { Gene.sync_with_remotes }
    EsCell.transaction { EsCell.sync_all_with_marts }
  end
end
