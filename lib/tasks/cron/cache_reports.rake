
begin

  namespace :cron do

    desc 'Generate cached reports'
    task :cache_reports => ['cron:reports:part3', 'cron:reports:part4', 'cron:reports:part5', 'cron:reports:part6']

    namespace :reports do

      task :part1 => [:environment] do
      end

      task :part2 => [:environment] do
      end

      task :part3 => [:environment] do
        ApplicationModel.audited_transaction do
          Reports::MiProduction::Intermediate.new.cache
        end
      end

      task :part4 => [:environment] do
        ApplicationModel.audited_transaction do
          Reports::ImpcGeneList.new.cache
        end
      end

      task :part5 => [:environment] do
        ApplicationModel.audited_transaction do
          Reports::MiProduction::PlannedMicroinjectionList.cache_all
          Reports::MiAttemptsList.new.cache
        end
      end

      task :part6 => [:environment] do
        ApplicationModel.audited_transaction do
          Reports::MiProduction::ImpcGraphReportDisplay.clear_charts_in_tmp_folder
        end
      end

      task :intermediate_report => [:environment] do
        NewIntermediateReport::Generate.cache
      end
    end

  end

end
