
begin

  namespace :cron do

    desc 'Generate cached reports'
    task :cache_reports => [ 'cron:reports:part3', 'cron:reports:part4', 'cron:reports:part5', 'cron:reports:part6']

    namespace :reports do

      task :part1 => [:environment] do
      end

      task :part2 => [:environment] do
      end

      task :part3 => [:environment] do
        ApplicationModel.audited_transaction do
        end
      end

      task :part4 => [:environment] do
        ApplicationModel.audited_transaction do
        end
      end

      task :part5 => [:environment] do
        ApplicationModel.audited_transaction do
        end
      end

      task :part6 => [:environment] do
        ApplicationModel.audited_transaction do
          Reports::MiProduction::ImpcGraphReportDisplay.clear_charts_in_tmp_folder
        end
      end

      task :intermediate_report => [:environment] do
        IntermediateReport::SummaryByMiPlan::Generate.cache
        IntermediateReport::SummaryByCentreAndConsortia::Generate.cache
        IntermediateReport::SummaryByConsortia::Generate.cache
        IntermediateReport::SummaryByCentre::Generate.cache
        IntermediateReport::SummaryByGene::Generate.cache
      end

      task :ikmc_project_update => [:environment] do
        ApplicationModel.audited_transaction do
          TargRep::IkmcProject::IkmcProjectGenerator::Generate.update_ikmc_projects
        end
      end

      task :gene_update => [:environment] do
        ApplicationModel.audited_transaction do
          Gene.update_gene_list
        end
      end

      task :part7 => [:environment] do
        puts "#### cron:reports:part7: NotificationsByGene idg"
        Reports::NotificationsByGene.new(nil, 'idg').cache

        puts "#### cron:reports:part7: NotificationsByGene cmg"
        Reports::NotificationsByGene.new(nil, 'cmg').cache

        consortia = Consortium.all.map(&:name)
        consortia = ['<all>', '<none>'] + consortia


        consortia.each do |consortium|
          puts "#### cron:reports:part7: NotificationsByGene #{consortium}"
          ApplicationModel.audited_transaction do
            Reports::NotificationsByGene.new(consortium).cache
          end
        end
      end

    end

  end

end
