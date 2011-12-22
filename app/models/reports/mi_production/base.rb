class Reports::MiProduction::Base
  def self.report_name; raise 'Override me!'; end

  def self.generate_and_cache
    cache = ReportCache.find_by_name(report_name)
    if cache
      cache.csv_data = self.generate.to_csv
      cache.save!
    else
      ReportCache.create!(
        :name => report_name,
        :csv_data => self.generate.to_csv
      )
    end
  end
end
