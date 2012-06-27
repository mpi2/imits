desc 'Generate cached reports'
task 'cron:cache_reports' => [:environment] do
  ApplicationModel.audited_transaction do
    Reports::MiProduction::SummaryMonthByMonthActivityImpc.new.cache
    Reports::MiProduction::SummaryMonthByMonthActivityKomp2.new.cache
    Reports::MiProduction::Intermediate.new.cache
    Reports::MiProduction::SummaryKomp23.new.cache
    Reports::MiProduction::SummaryImpc3.new.cache
    Reports::MiProduction::PlannedMicroinjectionList.cache_full
  end
end

desc 'Test cached reports'
task 'cron:cache_report_quick' => [:environment] do
  ApplicationModel.audited_transaction do
    Reports::MiProduction::PlannedMicroinjectionList.cache_full
  end
end
