namespace :cron do

  desc 'Clone production DB and reset passwords to "password"'
  task :clone_production_and_reset_passwords => ['db:production:clone', 'db:passwords:reset']

  desc 'MiPlan - Run major gene assignment/conflict resolution logic'
  task :major_conflict_resolution => [:environment] do
    ApplicationModel.audited_transaction { MiPlan.major_conflict_resolution }
  end

  desc 'MiPlan - Run minor conflict resolution logic'
  task :minor_conflict_resolution => [:environment] do
    ApplicationModel.audited_transaction { MiPlan.minor_conflict_resolution }
  end

  desc 'Gene/EsCell - Sync data caches with BioMarts and remote data sources'
  task :sync_data_with_remotes => [:environment] do
    ApplicationModel.audited_transaction { Gene.sync_with_remotes }
    ApplicationModel.audited_transaction { EsCell.sync_all_with_marts }
  end


  desc 'Sync MI attempt in progress dates'
  task :sync_mi_attempt_in_progress_dates => [:environment] do
    ApplicationModel.audited_transaction do
      log = "RAILS_ENV=#{Rails.env} rake cron:sync_mi_attempt_in_progress_dates\n"

      MiAttempt.all.each do |mi|
        ip_ss = mi.status_stamps.all.find {|i| i.mi_attempt_status == MiAttempt::Status.micro_injection_in_progress}
        ip_date = ip_ss.created_at.utc.to_date
        if ip_date != mi.mi_date
          log += "Changing '#{mi.colony_name}' in_progress_date from #{ip_date} to #{mi.mi_date}\n"
          ip_ss.created_at = Time.parse(mi.mi_date.to_s + ' 00:00 UTC')
          ip_ss.save!
        end
      end

      Rails.logger.info(log)
    end
  end

  desc 'Create phenotype attempt for KOMP2 micro-injections with Genotype confirmed status'
  task :create_komp2_phenotype_attempts => [:environment] do
    ApplicationModel.audited_transaction do
      log = "RAILS_ENV=#{Rails.env} rake cron:create_komp2_phenotype_attempts\n"

      MiAttempt.all.each do |mi|
        mi.create_phenotype_attempt_for_komp2
      end

      Rails.logger.info(log)
    end
  end
end
