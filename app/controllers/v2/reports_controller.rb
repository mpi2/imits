class V2::ReportsController < ApplicationController

  helper :reports

  before_filter :authenticate_user!

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

end