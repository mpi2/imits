# encoding: utf-8

class Reports::MiProduction::SummaryKomp23 < Reports::MiProduction::SummaryImpc3
  def self.report_name; 'production_summary_komp23'; end
  def self.report_title; 'KOMP2 Production Summary'; end
  def self.consortia; ['BaSH', 'DTCC', 'JAX']; end
end
