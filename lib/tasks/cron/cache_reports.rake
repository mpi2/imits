desc 'Generate cached reports'
task 'cron:cache_reports' => [:environment] do
  ApplicationModel.audited_transaction do
    Reports::MiProduction::SummaryMonthByMonthActivityImpc.new.cache
    Reports::MiProduction::SummaryMonthByMonthActivityKomp2.new.cache
    report = Reports::MiProduction::Intermediate.new
    report.cache
    Reports::MiProduction::SummaryKomp23.new.cache
    Reports::MiProduction::SummaryImpc3.new.cache
    IntermediateReport.generate(report)
  end
end

# TODO: remove these after tests

desc 'Generate cache table'
task 'cron:cache_table' => [:environment] do
  ApplicationModel.audited_transaction do
    IntermediateReport.generate
  end
end

desc 'Generate intermediate cache report'
task 'cron:cache_intermediate_report' => [:environment] do
  ApplicationModel.audited_transaction do
    Reports::MiProduction::Intermediate.new.cache
  end
end

desc 'Generate intermediate cache report (test)'
task 'cron:cache_intermediate_report_test' => [:environment] do
  ApplicationModel.audited_transaction do
    report = Reports::MiProduction::Intermediate.new
    report.cache
    IntermediateReport.generate(report)
  end
end
