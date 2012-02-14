desc 'Generate cached reports'
task 'cron:cache_reports' => [:environment] do
  ApplicationModel.audited_transaction do
    Reports::MiProduction::Intermediate.new.cache
    #Reports::MiProduction::SummaryKomp23.generate_and_cache
  end
end

