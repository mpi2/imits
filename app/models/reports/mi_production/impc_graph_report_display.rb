class Reports::MiProduction::ImpcGraphReportDisplay < Reports::MiProduction::SummaryMonthByMonthActivityImpcIntermediate

  def self.report_name; 'impc_graph_report_display'; end
  def self.report_title; 'IMPC Graph Report Display'; end
  def self.consortia; ['BaSH', 'DTCC', 'JAX']; end

end