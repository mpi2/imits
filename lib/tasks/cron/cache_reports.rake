desc 'Generate cached reports'
task 'cron:cache_reports' => [:environment] do
  ApplicationModel.audited_transaction do
    Reports::MiProduction::SummaryMonthByMonthActivityImpc.new.cache
    Reports::MiProduction::SummaryMonthByMonthActivityKomp2.new.cache
    Reports::MiProduction::Intermediate.new.cache
    Reports::MiProduction::SummaryKomp23.new.cache
    Reports::MiProduction::SummaryImpc3.new.cache
    Reports::MiProduction::PlannedMicroinjectionList.cache_all
    Reports::ImpcGeneList.new.cache
  end
end

task 'cron:cache_reports1' => [:environment] do
  STDERR.sync = true
  ApplicationModel.audited_transaction do
    STDERR.puts "Reports::MiProduction::SummaryMonthByMonthActivityImpc.new.cache"
    Reports::MiProduction::SummaryMonthByMonthActivityImpc.new.cache
  end

  ApplicationModel.audited_transaction do
    STDERR.puts "Reports::MiProduction::SummaryMonthByMonthActivityKomp2.new.cache"
    Reports::MiProduction::SummaryMonthByMonthActivityKomp2.new.cache
  end

  ApplicationModel.audited_transaction do
    STDERR.puts "Reports::MiProduction::Intermediate.new.cache"
    Reports::MiProduction::Intermediate.new.cache
  end
end

task 'cron:cache_reports2' => [:environment] do
  STDERR.sync = true
  ApplicationModel.audited_transaction do
    STDERR.puts "Reports::MiProduction::SummaryKomp23.new.cache"
    Reports::MiProduction::SummaryKomp23.new.cache
  end

  ApplicationModel.audited_transaction do
    STDERR.puts "Reports::MiProduction::SummaryImpc3.new.cache"
    Reports::MiProduction::SummaryImpc3.new.cache
  end

  ApplicationModel.audited_transaction do
    STDERR.puts "Reports::ImpcGeneList.new.cache"
    Reports::ImpcGeneList.new.cache
  end
end

task 'cron:cache_reports3' => [:environment] do
  STDERR.sync = true
  ApplicationModel.audited_transaction do
    STDERR.puts "Reports::MiProduction::PlannedMicroinjectionList.cache_all"
    Reports::MiProduction::PlannedMicroinjectionList.cache_all
  end
end