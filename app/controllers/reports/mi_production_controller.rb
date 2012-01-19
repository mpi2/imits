# encoding: utf-8

class Reports::MiProductionController < ApplicationController

  respond_to :html, :csv

  before_filter :authenticate_user!, :except => [:summary_by_consortium_and_accumulated_status]

  def test
    if request.format == :csv
    	report = ReportCache.find_by_name!('mi_production_intermediate_test')
      send_data_csv('test.csv', report.csv_data)
    end
  end

  def detail
    if request.format == :csv
      send_data_csv('mi_production_detail.csv', Reports::MiProduction::Detail.generate.to_csv)
    end
  end

  def intermediate
    report = ReportCache.find_by_name!('mi_production_intermediate')
    send_data_csv("mi_production_intermediate-#{report.compact_timestamp}.csv", report.csv_data)
  end

  def index
  end

  def summary_by_consortium_and_accumulated_status
    @csv = Reports::MiProduction::FeedImpc::CSV_LINKS
    feed = (params[:feed] == 'true')
    @title2, @report = Reports::MiProduction::FeedImpc.generate(request, params)
    send_data_csv('mi_production_summary_by_consortium_and_accumulated_status.csv', @report.to_csv) if request.format == :csv
    render :text => @report.to_html, :layout => false if feed
  end

  def summary_by_consortium
    @csv = Reports::MiProduction::SummaryByConsortium::CSV_LINKS
    @title2, @report = Reports::MiProduction::SummaryByConsortium.generate(request, params)
    send_data_csv('summary_by_consortium.csv', @report.to_csv) if request.format == :csv
  end

  def summary_by_consortium_priority
    @csv = Reports::MiProduction::SummaryByConsortiumPriority::CSV_LINKS
    @title2, @report = Reports::MiProduction::SummaryByConsortiumPriority.generate(request, params)
    send_data_csv('Summary_by_consortium_priority.csv', @report.to_csv) if request.format == :csv
  end

  def summary_mgp
    @csv = Reports::MiProduction::SummaryMgp::CSV_LINKS
    @title2, @report = Reports::MiProduction::SummaryMgp.generate(request, params)
    send_data_csv('summary_mgp.csv', @report.to_csv) if request.format == :csv
  end

  def summary_komp2_brief
    @csv = Reports::MiProduction::SummaryKomp2Brief::CSV_LINKS
    @title2, @report = Reports::MiProduction::SummaryKomp2Brief.generate(request, params)
    send_data_csv('production_summary_komp2_brief.csv', @report.to_csv) if request.format == :csv
  end

  def summary_komp2
    @csv = Reports::MiProduction::SummaryKomp2::CSV_LINKS
    @title2, @report = Reports::MiProduction::SummaryKomp2.generate(request, params)
    send_data_csv('production_summary_komp2.csv', @report) if request.format == :csv
  end

  def summary_komp21
    @csv = Reports::MiProduction::SummaryKomp21::CSV_LINKS
    @title2, @report = Reports::MiProduction::SummaryKomp21.generate(request, params)
    send_data_csv('production_summary_komp21.csv', @report.to_csv) if request.format == :csv
  end

  def languishing
    @report = Reports::MiProduction::Languishing.generate(:consortia => params[:consortia])
  end

end
