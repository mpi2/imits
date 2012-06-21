desc 'Generate cached reports'
task 'cron:cache_reports' => [:environment] do
  ApplicationModel.audited_transaction do
    Reports::MiProduction::SummaryMonthByMonthActivityImpc.new.cache
    Reports::MiProduction::SummaryMonthByMonthActivityKomp2.new.cache
    Reports::MiProduction::Intermediate.new.cache
    Reports::MiProduction::SummaryKomp23.new.cache
    Reports::MiProduction::SummaryImpc3.new.cache
    Reports::ImpcGeneList.new.cache
  end
end

desc 'Generate cached report for impc'
task 'cron:cache_report_impc_list' => [:environment] do
  ApplicationModel.audited_transaction do
    Reports::ImpcGeneList.new.cache
  end
end
