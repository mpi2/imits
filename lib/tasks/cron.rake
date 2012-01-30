namespace :cron do
  def audited_transaction
    ActiveRecord::Base.transaction do
      Audit.as_user(User.find_by_email! 'htgt@sanger.ac.uk') do
        yield
      end
    end
  end

  desc 'Clone production DB and reset passwords to "password"'
  task :clone_production_and_reset_passwords => ['db:production:clone', 'db:passwords:reset']

  desc 'MiPlan - Run major gene assignment/conflict resolution logic'
  task :major_conflict_resolution => [:environment] do
    audited_transaction { MiPlan.major_conflict_resolution }
  end

  desc 'MiPlan - Run minor conflict resolution logic'
  task :minor_conflict_resolution => [:environment] do
    audited_transaction { MiPlan.minor_conflict_resolution }
  end

  desc 'MiPlan - Mark old unsuccessful MiPlans as "Inactive"'
  task :mark_old_plans_as_inactive => [:environment] do
    audited_transaction { MiPlan.mark_old_plans_as_inactive }
  end

  desc 'Gene/EsCell - Sync data caches with BioMarts and remote data sources'
  task :sync_data_with_remotes => [:environment] do
    audited_transaction { Gene.sync_with_remotes }
    audited_transaction { EsCell.sync_all_with_marts }
  end

  desc 'Generate cached reports'
  task :cache_reports => [:environment] do
    audited_transaction do
      Reports::MiProduction::Intermediate.generate_and_cache
    end
  end

  desc 'Sync MI attempt in progress dates'
  task :sync_mi_attempt_in_progress_dates => [:environment] do
    audited_transaction do
      log = "RAILS_ENV=#{Rails.env} rake cron:sync_mi_attempt_in_progress_dates\n"

      bad_mis = MiAttempt.find_all_by_colony_name(%w{UCD-EPD0413_5_E10-1 UCD-DEPD00514_4_H02-1 ICS-EPD0177_1_E09-1})
      bad_mis.each do |mi|
          log += "Changing '#{mi.colony_name}' mi_date from #{mi.mi_date} to #{mi.in_progress_date}\n"
        mi.mi_date = mi.in_progress_date
        mi.save!
      end

      MiAttempt.all.each do |mi|
        ip_ss = mi.status_stamps.all.find {|i| i.mi_attempt_status == MiAttemptStatus.micro_injection_in_progress}
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

end
