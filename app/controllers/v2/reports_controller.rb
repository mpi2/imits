class V2::ReportsController < ApplicationController

  helper :reports

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

  def qc_grid
    @report = QcGridReport.new
    @mi_attempts = @report.mi_attempts
  end

end