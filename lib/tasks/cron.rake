namespace :cron do
  desc 'Clone production DB and reset passwords to "password"'
  task :clone_production_and_reset_passwords => ['db:production:clone', 'db:passwords:reset']

  desc 'MiPlan - Run major gene assignment/conflict resolution logic'
  task :major_conflict_resolution => [:environment] do
    MiPlan.transaction { MiPlan.major_conflict_resolution }
  end

  desc 'MiPlan - Run minor conflict resolution logic'
  task :minor_conflict_resolution => [:environment] do
    MiPlan.transaction { MiPlan.minor_conflict_resolution }
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
