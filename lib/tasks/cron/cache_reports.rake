
begin

  namespace :cron do

    desc 'Generate cached reports'
    task :cache_reports => ['cron:reports:part1', 'cron:reports:part2', 'cron:reports:part3', 'cron:reports:part4', 'cron:reports:part5']

    namespace :reports do

      task :part1 => [:environment] do
        puts "part1..."
        STDOUT.flush
        ApplicationModel.audited_transaction do
          Reports::MiProduction::SummaryMonthByMonthActivityImpc.new.cache
        end
      end

      task :part2 => [:environment] do
        ApplicationModel.audited_transaction do
          Reports::MiProduction::SummaryMonthByMonthActivityKomp2.new.cache
        end
      end

      task :part3 => [:environment] do
        ApplicationModel.audited_transaction do
          Reports::MiProduction::Intermediate.new.cache
        end
      end

      task :part4 => [:environment] do
        ApplicationModel.audited_transaction do
          Reports::MiProduction::SummaryKomp23.new.cache
        end

        ApplicationModel.audited_transaction do
          Reports::MiProduction::SummaryImpc3.new.cache
        end

        ApplicationModel.audited_transaction do
          Reports::ImpcGeneList.new.cache
        end
      end

      task :part5 => [:environment] do
        ApplicationModel.audited_transaction do
          Reports::MiProduction::PlannedMicroinjectionList.cache_all
        end
      end

    end

  end

end
