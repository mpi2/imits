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
                :delay_bin => bin,
                :only_path => true) + '">' + record[bin].to_s + '</a>'
            end
            css_classes = ['center', record[0].gsub(/[- ]+/, '_').downcase, "bin#{idx}"]
            record[bin] = "<div class=\"#{css_classes.join ' '}\">#{link}</div>".html_safe
          end
        end

        {
          'Micro-injection in progress' => 'Mouse production attempt',
          'Phenotype Attempt Registered' => 'Intent to phenotype'
        }.each do |from, to|
          row = group.find {|r| r[0] == from}
          row[0] = to
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

  def mgp_summary_subproject
    @csv = Reports::MiProduction::SummaryMgp23::CSV_LINKS
    return_value = Reports::MiProduction::SummaryMgp23.generate('Sub-Project',request)
    #raise return_value[:table].inspect
    @report = return_value[:table]
    if request.format == :csv
      send_data_csv('summary_mgp.csv', @report.to_csv)
    else
      render :action => 'mgp_summary'
    end
  end

  def mgp_summary_priority
    @csv = Reports::MiProduction::SummaryMgp23::CSV_LINKS
    return_value = Reports::MiProduction::SummaryMgp23.generate('Priority',request)
    #raise return_value[:table].inspect
    @report = return_value[:table]
    if request.format == :csv
      send_data_csv('summary_mgp.csv', @report.to_csv)
    else
      render :action => 'mgp_summary'
    end
  end

  def mgp_detail
    @csv = Reports::MiProduction::SummaryMgp23::CSV_LINKS
    return_value = Reports::MiProduction::SummaryMgp23.generate_detail(request,params)
    #raise return_value[:table].inspect
    @report = return_value[:table]
    if request.format == :csv
      send_data_csv('summary_mgp.csv', @report.to_csv)
    end
  end

  def languishing_mgp_priority
    @report = Reports::MiProduction::LanguishingMgp.generate('Priority')
    if request.format == :html
      @report.each do |the_priority, group|
        group.each do |record|
          Reports::MiProduction::Languishing::DELAY_BINS.each_with_index do |bin, idx|
            if record[bin] == 0
              link = '&nbsp;'.html_safe
            else
              link = '<a href="' + url_for(:controller => '/reports/mi_production',
                :action => 'languishing_mgp_detail',
                :priority => the_priority,
                :status => record[0],
                :delay_bin => bin) + '">' + record[bin].to_s + '</a>'
            end
            css_classes = ['center', record[0].gsub(/[- ]+/, '_').downcase, "bin#{idx}"]
            record[bin] = "<div class=\"#{css_classes.join ' '}\">#{link}</div>".html_safe
          end
        end
        {
              'Micro-injection in progress' => 'Mouse production attempt',
              'Phenotype Attempt Registered' => 'Intent to phenotype'
        }.each do |from, to|
              row = group.find {|r| r[0] == from}
              row[0] = to
        end
      end
    end

    if params[:consortia].blank?
      name = 'languishing_production_mgp_report.csv'
    end

    if request.format == :csv
      send_data_csv(name, @report.to_csv)
    else
      render :action => 'languishing_mgp'
    end
  end

  def languishing_mgp_sub_project
    @report = Reports::MiProduction::LanguishingMgp.generate('Sub-Project')
    if request.format == :html
      @report.each do |sub_project, group|
        group.each do |record|
          Reports::MiProduction::Languishing::DELAY_BINS.each_with_index do |bin, idx|
            if record[bin] == 0
              link = '&nbsp;'.html_safe
            else
              link = '<a href="' + url_for(:controller => '/reports/mi_production',
                :action => 'languishing_mgp_detail',
                :sub_project => sub_project,
                :status => record[0],
                :delay_bin => bin) + '">' + record[bin].to_s + '</a>'
            end
            css_classes = ['center', record[0].gsub(/[- ]+/, '_').downcase, "bin#{idx}"]
            record[bin] = "<div class=\"#{css_classes.join ' '}\">#{link}</div>".html_safe
          end
        end
        {
              'Micro-injection in progress' => 'Mouse production attempt',
              'Phenotype Attempt Registered' => 'Intent to phenotype'
        }.each do |from, to|
              row = group.find {|r| r[0] == from}
              row[0] = to
        end
      end
    end


    if params[:consortia].blank?
      name = 'languishing_production_mgp_report.csv'
    end

    if request.format == :csv
      send_data_csv(name, @report.to_csv)
    else
      render :action => 'languishing_mgp'
    end
  end

  def languishing_mgp_detail
    @report = Reports::MiProduction::LanguishingMgp.generate_detail(
      :priority => params[:priority],
      :sub_project => params[:sub_project],
      :status => params[:status],
      :delay_bin => params[:delay_bin])
    send_data_csv('languishing_production_report_mgp_detail.csv', @report.to_csv) if request.format == :csv
  end

end
