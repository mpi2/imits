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
    report = ReportCache.find_by_name_and_format!('mi_production_intermediate', 'csv')
    send_data_csv("mi_production_intermediate-#{report.compact_timestamp}.csv", report.data)
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

  def summary_3_helper(report_class)
    @title2 = report_class.report_title

    if params[:consortium]
      params[:format] = request.format
      params[:script_name] = request.env['REQUEST_URI']
      @report_data = report_class.generate(params)
      @title2 = @report_data[:title]

      if request.format == :csv
        send_data_csv("#{report_class.report_name}_detail.csv", @report_data[:csv])
      else
        render :action => 'summary_3'
      end
      return
    end

    query = ReportCache.where(:name => report_class.report_name)

    @report_data = { :csv => query.where(:format => 'csv').first.data, :html => query.where(:format => 'html').first.data}

    if request.format == :csv
      send_data_csv("#{report_class.report_name}.csv", @report_data[:csv])
    else
      render :action => 'summary_3'
    end
  end
  private :summary_3_helper

  def summary_komp23
    summary_3_helper(Reports::MiProduction::SummaryKomp23)
  end

  def summary_impc3
    summary_3_helper(Reports::MiProduction::SummaryImpc3)
  end

  def languishing
    @report = Reports::MiProduction::Languishing.generate(
      :consortia => params[:consortia])
    if request.format == :html
      format_languishing_report(@report,
        :group_type => :consortium,
        :details_controller => '/reports/mi_production',
        :details_action => 'languishing_detail')
    end

    if params[:consortia].blank?
      name = 'languishing_production_report.csv'
    else
      name = "languishing_production_report-#{params[:consortia]}.csv"
    end
    send_data_csv(name, @report.to_csv) if request.format == :csv
  end

  def languishing_detail
    @report = Reports::MiProduction::Languishing.generate_detail(
      :consortium => params[:consortium],
      :status => params[:status],
      :delay_bin => params[:delay_bin])
    send_data_csv('languishing_production_report_detail.csv', @report.to_csv) if request.format == :csv
  end

  def month_by_month_helper(report_class)
    @title2 = report_class.report_title

    if params[:consortium]
      params[:format] = request.format
      params[:script_name] = request.env['REQUEST_URI']
      @report_data = report_class.generate(params)
      @title2 = @report_data[:title]

      if request.format == :csv
        send_data_csv("#{report_class.report_name}_detail.csv", @report_data[:csv])
      else
        render :action => 'month_by_month'
      end
      return
    end

    query = ReportCache.where(:name => report_class.report_name)

    @report_data = { :csv => query.where(:format => 'csv').first.data, :html => query.where(:format => 'html').first.data}

    if request.format == :csv
      send_data_csv("#{report_class.report_name}.csv", @report_data[:csv])
    else
      render :action => 'month_by_month'
    end
  end

  private :summary_3_helper

  def summary_month_by_month_activity_impc
    month_by_month_helper(Reports::MiProduction::SummaryMonthByMonthActivityImpc)
  end

  def summary_month_by_month_activity_komp2
    month_by_month_helper(Reports::MiProduction::SummaryMonthByMonthActivityKomp2)
  end

  def month_by_month_helper_no_cache(report_class)
    @title2 = report_class.report_title

    params[:script_name] = url_for(:action => 'summary_month_by_month_activity_impc')
    @report_data = report_class.generate(params)

    if request.format == :csv
      send_data_csv("#{report_class.report_name}.csv", @report_data[:csv])
    else
      render :action => 'month_by_month'
    end
  end

  def summary_month_by_month_activity_all_centres_impc
    month_by_month_helper_no_cache(Reports::MiProduction::SummaryMonthByMonthActivityAllCentresImpc)
  end

  def summary_month_by_month_activity_all_centres_komp2
    month_by_month_helper_no_cache(Reports::MiProduction::SummaryMonthByMonthActivityAllCentresKomp2)
  end

end
