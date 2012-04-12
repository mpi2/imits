class Reports::Production::MgpController < ApplicationController
  def index
  end

  def summary_subproject
    @csv = Reports::MiProduction::SummaryMgp23::CSV_LINKS
    return_value = Reports::MiProduction::SummaryMgp23.generate('Sub-Project', request)
    @report = return_value[:table]
    if request.format == :csv
      send_data_csv('mgp_summary_subproject.csv', @report.to_csv)
    else
      render :action => 'summary'
    end
  end
end
