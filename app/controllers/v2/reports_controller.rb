class V2::ReportsController < ApplicationController

  helper :reports

  before_filter :authenticate_user!, :except => [:komp_project, :idcc_master_genelist]

  before_filter do
    if params[:format] == 'csv'
      response.headers["Cache-Control"] = "no-cache"
      response.headers["Content-Type"] = "text/csv"
      response.headers["Content-Disposition"] = "attachment;filename=#{action_name}-#{Date.today.to_s(:db)}.csv"
    end
  end

  before_filter do
    if params[:format] == 'tab'
      response.headers["Cache-Control"] = "no-cache"
      response.headers["Content-Type"] = "text"
      response.headers["Content-Disposition"] = "attachment;filename=#{action_name}-#{Date.today.to_s(:db)}.tab"
    end
  end

  def index
    redirect_to reports_path
  end

  def planned_microinjection_summary_and_conflicts
    @report = MicroInjectionSummaryAndConflictsReport.new
    @consortia_by_priority = @report.consortia_by_priority
    @consortia_by_status = @report.consortia_by_status
    @consortia_totals = @report.consortia_totals
    @priority_totals = @report.priority_totals
    @status_totals = @report.status_totals
    @consortia = @report.consortia

    @statuses = @report.class.statuses
    @priorities = @report.class.priorities
  end

  def qc_grid_summary
    @report = QcGridReport::Summary.new
    @centre_by_consortia = @report.centre_by_consortia
    @score_averages = @report.generate_report
  end

  def qc_grid
    @report = QcGridReport.new

    @report.conditions = params
    @report.run

    @report_rows = @report.report_rows
  end

  def komp_project
    @report= IkmcProjectFeed.new
    @komp_project = @report.komp_project
  end

  def idcc_master_genelist
    @report= IkmcProjectFeed.new
    @idcc_master_genelist = @report.idcc_master_genelist.to_a
  end
end