# encoding: utf-8

class Reports::MiProductionController < ApplicationController

  respond_to :html, :csv

  before_filter :authenticate_user!, :except => [:summary_by_consortium_and_accumulated_status]

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

end
