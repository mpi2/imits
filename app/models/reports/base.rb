class Reports::Base
  def self.report_name; raise 'Override me!'; end

  def cache
    cache = ReportCache.find_by_name(self.class.report_name)
    if ! cache
      cache = ReportCache.new(
        :name => self.class.report_name,
        :csv_data => '',
        :html_data => '<div></div>'
      )
    end

    cache.html_data = self.to(:html)
    cache.csv_data = self.to(:csv)
    cache.save!
  end

  def to(format)
    @report.send("to_#{format}")
  end

  protected

  def generate
    raise 'override me'
  end

end
