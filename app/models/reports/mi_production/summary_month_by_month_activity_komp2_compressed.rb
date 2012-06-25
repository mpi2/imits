# encoding: utf-8

class Reports::MiProduction::SummaryMonthByMonthActivityKomp2Compressed < Reports::MiProduction::SummaryMonthByMonthActivityImpc
  def self.report_name; 'summary_month_by_month_activity_komp2'; end
  def self.report_title; 'KOMP2 Summary Month by Month'; end
  def self.consortia; ['BaSH', 'DTCC', 'JAX']; end

  def initialize
    generated = self.class.generate :komp2 => true
    @csv = generated[:csv]
    @html = generated[:html]
  end
end
