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
    send_data_csv('production_summary_komp212.csv', @report.to_csv) if request.format == :csv
  end

  def summary_komp22
    @csv = Reports::MiProduction::SummaryKomp22::CSV_LINKS
    @title2, @report = Reports::MiProduction::SummaryKomp22.generate(request, params)
    send_data_csv('production_summary_komp22.csv', @report) if request.format == :csv
  end

  def summary_komp23

    @csv = Reports::MiProduction::SummaryKomp23::CSV_LINKS
    @title2 = Reports::MiProduction::SummaryKomp23::REPORT_TITLE    

    if params[:live] || params[:consortium]
      params[:format] = request.format
      params[:komp2] = true
      params[:script_name] = request.env['REQUEST_URI']
      @report_renderer = Reports::MiProduction::SummaryKomp23.generate(params)
      @title2 = @report_renderer[:title]
      send_data_csv('production_summary_komp23.csv', @report_renderer[:csv]) if request.format == :csv
      return
    end
    
    @report = ReportCache.find_by_name!('komp2_production_summary')
    
    @report_renderer = { :csv => @report.csv_data, :html => @report.html_data }

    send_data_csv('production_summary_komp23.csv', @report_renderer[:csv]) if request.format == :csv

  end

  def summary_impc23
    @csv = Reports::MiProduction::SummaryKomp23::CSV_LINKS
    params[:format] = request.format
    params[:komp2] = false
    params[:script_name] = request.env['REQUEST_URI']
    @report_renderer = Reports::MiProduction::SummaryKomp23.generate(params)
    @title2 = @report_renderer[:title]
    send_data_csv('summary_impc23.csv', @report_renderer[:csv]) if request.format == :csv
  end

  def languishing
    @report = Reports::MiProduction::Languishing.generate(
      :consortia => params[:consortia])
    if request.format == :html
      @report.each do |consortium, group|
        group.each do |record|
          Reports::MiProduction::Languishing::DELAY_BINS.each_with_index do |bin, idx|
            if record[bin] == 0
              link = '&nbsp;'.html_safe
            else
              link = '<a href="' + url_for(:controller => '/reports/mi_production',
                :action => 'languishing_detail',
                :consortium => consortium,
                :status => record[0],
                :delay_bin => bin) + '">' + record[bin].to_s + '</a>'
            end
            css_classes = [record[0].gsub(/[- ]+/, '_').downcase, "bin#{idx}"]
            record[bin] = "<div class=\"#{css_classes.join ' '}\">#{link}</div>".html_safe
          end
        end
      end
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

  def summary_month_by_month_activity
    params[:format] = request.format
    params[:komp2] = true #TODO: remove me! set in view
    params[:script_name] = request.env['REQUEST_URI']
    @report_renderer = Reports::MiProduction::SummaryMonthByMonthActivity.generate(params)
    @title2 = @report_renderer[:title]
    send_data_csv('summary_month_by_month_activity.csv', @report_renderer[:csv]) if request.format == :csv
  end

end
