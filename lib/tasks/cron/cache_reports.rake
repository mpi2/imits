#desc 'Generate cached reports'
#task 'cron:cache_reports' => [:environment] do
#  ApplicationModel.audited_transaction do
#    Reports::MiProduction::SummaryMonthByMonthActivityImpc.new.cache
#    Reports::MiProduction::SummaryMonthByMonthActivityKomp2.new.cache
#    Reports::MiProduction::Intermediate.new.cache
#    Reports::MiProduction::SummaryKomp23.new.cache
#    Reports::MiProduction::SummaryImpc3.new.cache
#    Reports::MiProduction::PlannedMicroinjectionList.cache_all
#    Reports::ImpcGeneList.new.cache
#  end
#end

desc 'Generate cached reports'
task 'cron:cache_reports' => [:environment] do
  ApplicationModel.audited_transaction do
    Reports::MiProduction::SummaryMonthByMonthActivityImpc.new.cache
  end

  ApplicationModel.audited_transaction do
    Reports::MiProduction::SummaryMonthByMonthActivityKomp2.new.cache
  end

  ApplicationModel.audited_transaction do
    Reports::MiProduction::Intermediate.new.cache
  end

  ApplicationModel.audited_transaction do
    Reports::MiProduction::SummaryKomp23.new.cache
  end

  ApplicationModel.audited_transaction do
    Reports::MiProduction::SummaryImpc3.new.cache
  end

  ApplicationModel.audited_transaction do
    Reports::MiProduction::PlannedMicroinjectionList.cache_all
  end

  ApplicationModel.audited_transaction do
    Reports::ImpcGeneList.new.cache
  end
end
