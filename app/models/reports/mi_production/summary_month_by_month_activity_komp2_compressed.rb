# encoding: utf-8

class Reports::MiProduction::SummaryMonthByMonthActivityKomp2Compressed < Reports::MiProduction::SummaryMonthByMonthActivityImpcIntermediate

  def self.report_name; 'summary_month_by_month_activity_komp2_compressed'; end
  def self.report_title; 'KOMP2 Summary Month by Month'; end
  def self.consortia; ['BaSH', 'DTCC', 'JAX']; end

end
