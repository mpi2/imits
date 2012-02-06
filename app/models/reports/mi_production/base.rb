class Reports::MiProduction::Base
  def self.report_name; raise 'Override me!'; end

  def self.generate_and_cache
    cache = ReportCache.find_by_name(report_name)
    if ! cache
      cache = ReportCache.new(
        :name => report_name,
        :csv_data => self.generate.to_csv,
        :html_data => '<div></div>'
      )
    end

    report = self.generate
    cache.csv_data = report.to_csv
    cache.html_data = report.to_html
    cache.save!
  end
end
