# encoding: utf-8

class Reports::MiProduction::SummaryKomp2

  extend Reports::MiProduction::SummariesCommon
  extend Reports::MiProduction::SummaryKomp2Common

  CSV_LINKS = Reports::MiProduction::SummaryKomp2Common::CSV_LINKS  
  REPORT_TITLE = 'KOMP2 Report'

  def self.generate(request = nil, params={})
    
    if params[:consortium]
      title, report = subsummary_common(params)
      rv = request && request.format == :csv ? report.to_csv : report.to_html
      return title, rv
    end

    report = generate_common(request, params)
    
    return REPORT_TITLE, report.to_csv if request && request.format == :csv    
    return REPORT_TITLE, report.to_html
  end
  
end
