class Reports::MiAttemptsList < Reports::Base

  include Reports::Helper

  def self.report_name; 'full_mi_attempts_list'; end

  def to_csv
    @report.to_csv
  end

  def to_html
    @report.to_html
  end

  def initialize
    @report = generate_mi_list_report
  end

end
