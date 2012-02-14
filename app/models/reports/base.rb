class Reports::Base
  def self.report_name; raise 'Override me!'; end

  def cache
    ReportCache.transaction do
      ['html', 'csv'].each do |format|
        cache = ReportCache.find_by_name_and_format(self.class.report_name, format)
        if ! cache
          cache = ReportCache.new(
            :name => self.class.report_name,
            :data => '',
            :format => format
          )
        end

        cache.data = self.to(format)
        cache.save!
      end
    end
  end

  def to(format)
    @report.send("to_#{format}")
  end
end
