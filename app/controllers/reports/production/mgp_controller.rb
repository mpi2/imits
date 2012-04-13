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

  def summary_priority
    @csv = Reports::MiProduction::SummaryMgp23::CSV_LINKS
    return_value = Reports::MiProduction::SummaryMgp23.generate('Priority', request)
    @report = return_value[:table]
    if request.format == :csv
      send_data_csv('mgp_summary_subproject.csv', @report.to_csv)
    else
      render :action => 'summary'
    end
  end

  def detail
    @csv = Reports::MiProduction::SummaryMgp23::CSV_LINKS
    return_value = Reports::MiProduction::SummaryMgp23.generate_detail(request, params)
    @report = return_value[:table]
    if request.format == :csv
      send_data_csv('mgp_summary_detail.csv', @report.to_csv)
    end
  end

  def languishing_sub_project
    @report = Reports::MiProduction::LanguishingMgp.generate('Sub-Project')
    if request.format == :html
      format_languishing_report(@report,
        :group_type => :sub_project,
        :details_controller => '/reports/production/mgp',
        :details_action => 'languishing_detail')
    end

    if request.format == :csv
      send_data_csv('mgp_languishing_sub_project_production_report.csv', @report.to_csv)
    else
      render :action => 'languishing'
    end
  end

  def languishing_priority
    @report = Reports::MiProduction::LanguishingMgp.generate('Priority')
    if request.format == :html
      format_languishing_report(@report,
        :group_type => :priority,
        :details_controller => '/reports/production/mgp',
        :details_action => 'languishing_detail')
    end

    if request.format == :csv
      send_data_csv('mgp_languishing_priority_production_report.csv', @report.to_csv)
    else
      render :action => 'languishing'
    end
  end

  def languishing_detail
    @report = Reports::MiProduction::LanguishingMgp.generate_detail(
      :priority => params[:priority],
      :sub_project => params[:sub_project],
      :status => params[:status],
      :delay_bin => params[:delay_bin])

    if request.format == :csv
      send_data_csv('languishing_production_report_mgp_detail.csv', @report.to_csv)
    end
  end

end # Reports::Production::MgpController
