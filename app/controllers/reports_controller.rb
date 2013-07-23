# encoding: utf-8

class ReportsController < ApplicationController
  respond_to :html, :csv

  before_filter :authenticate_user!, :except => [:impc_gene_list]

  layout :check_remote_load

  extend Reports::Helper
  include Reports::Helper

  def index
  end

  def double_assigned_plans_matrix
    @report = Reports::MiPlans::DoubleAssignment.get_matrix
    send_data_csv('double_assigned_matrix.csv', @report.to_csv)
  end

  def double_assigned_plans_list
    @report = Reports::MiPlans::DoubleAssignment.get_list
    send_data_csv('double_assigned_list.csv', @report.to_csv)
  end

  def double_assigned_plans
    @report1 = Reports::MiPlans::DoubleAssignment.get_matrix
    @report2 = Reports::MiPlans::DoubleAssignment.get_list
  end

  def notifications_by_gene
    @report = Notification.notifications_by_gene
  end

  def genes_list
    @report = Table(
      [
        'Marker Symbol',
        'MGI Accession ID',
        '# IKMC Projects',
        '# Clones',
        'Non-Assigned Plans',
        'Assigned Plans',
        'Aborted MIs',
        'MIs in Progress',
        'GLT Mice'
      ]
    )

    non_assigned_mis = Gene.pretty_print_non_assigned_mi_plans_in_bulk
    assigned_mis     = Gene.pretty_print_assigned_mi_plans_in_bulk
    mis_in_progress  = Gene.pretty_print_mi_attempts_in_progress_in_bulk
    glt_mice         = Gene.pretty_print_mi_attempts_genotype_confirmed_in_bulk
    aborted_mis      = Gene.pretty_print_aborted_mi_attempts_in_bulk

    Gene.select('marker_symbol, mgi_accession_id, ikmc_projects_count, conditional_es_cells_count, non_conditional_es_cells_count, deletion_es_cells_count')
      .order('marker_symbol asc').each do |gene|
      @report << [
        gene.marker_symbol,
        gene.mgi_accession_id,
        gene.ikmc_projects_count,
        gene.pretty_print_types_of_cells_available.gsub('<br/>',' '),
        non_assigned_mis[gene.marker_symbol] ? non_assigned_mis[gene.marker_symbol].gsub('<br/>',' ') : nil,
        assigned_mis[gene.marker_symbol] ? assigned_mis[gene.marker_symbol].gsub('<br/>',' ') : nil,
        aborted_mis[gene.marker_symbol] ? aborted_mis[gene.marker_symbol].gsub('<br/>',' ') : nil,
        mis_in_progress[gene.marker_symbol] ? mis_in_progress[gene.marker_symbol].gsub('<br/>',' ') : nil,
        glt_mice[gene.marker_symbol] ? glt_mice[gene.marker_symbol].gsub('<br/>',' ') : nil
      ]
    end

    send_data(
      @report.to_csv,
      :type     => 'text/csv; charset=utf-8; header=present',
      :filename => 'genes_list.csv'
    )
  end

  def full_report?
    params[:consortium_id].blank? && params[:grouping].blank? && params[:production_centre_id].blank?
  end

  def mi_attempts_list

    unless params[:commit].blank?

      if full_report?
        @cached = true

        if request.format == :csv
          if cached_report = ReportCache.find_by_name_and_format('full_mi_attempts_list', 'csv')
            send_data(
              cached_report.data,
              :type     => 'text/csv; charset=utf-8; header=present',
              :filename => 'full_mi_attempts_list.csv'
            )  and return

          else
            @cached = false
          end
        else
          @report = ReportCache.find_by_name_and_format('full_mi_attempts_list', 'html')

          if @report.blank?
            @cached = false
          end
        end
      end

      unless @cached
        @report = generate_mi_list_report( params )

        if @report.nil?
          redirect_to cleaned_redirect_params( :mi_attempts_list, params ) if request.format == :csv
          return
        end

        @report.sort_rows_by!( 'Injection Date', :order => :descending )
        @report = Grouping( @report, :by => params[:grouping], :order => :name ) unless params[:grouping].blank?

        if request.format == :csv
          send_data(
            @report.to_csv,
            :type     => 'text/csv; charset=utf-8; header=present',
            :filename => 'mi_attempts_list.csv'
          )
        end
      end
    end
  end

  def mi_attempts_monthly_production
    unless params[:commit].blank?
      @report = Reports::MonthlyProduction.generate(request, params)
      send_data_csv('mi_attempts_monthly_production.csv', @report.to_csv) if request.format == :csv
    end
  end

  def mi_attempts_by_gene
    unless params[:commit].blank?
      @report = Reports::GeneSummary.generate(request, params)
      send_data_csv('mi_attempts_by_gene.csv', @report.to_csv) if request.format == :csv
    end
  end

  def planned_microinjection_list
    consortium_name = ''
    if params && params[:consortium_id] && ! params[:consortium_id][0].blank?
      consortium = Consortium.find_by_id(params[:consortium_id])
      consortium_name = consortium.name
    end
    report = ''
    report_cache = ReportCache.find_by_name_and_format("planned_microinjection_list_#{consortium_name}", 'csv')
    if ! report_cache.blank?
      report = report_cache.to_table
      if !current_user.can_see_sub_project?
        report.remove_column('SubProject')
      end
      @report_data = report.to_html
    end
    @consortium = consortium_name.blank? ? 'All' : consortium_name
    @count = report.blank? ? 0 : report.length

    if request.format == :csv
      filename = "planned_microinjection_list_" + consortium_name.gsub(/[\s-]/, "_").downcase + ".csv"
      data = report.blank? ? '' : report.to_csv
      send_data_csv(filename, data)
    end
  end

  def planned_microinjection_summary_and_conflicts
    redirect_to url_for(:controller => "v2/reports", :action => :planned_microinjection_summary_and_conflicts) and return
  end

  def impc_gene_list
    cache = ReportCache.find_by_name_and_format('impc_gene_list', 'csv')
    send_data(
      cache && cache.data ? cache.data : '',
      :type     => 'text/csv; charset=utf-8; header=present',
      :filename => 'impc_gene_list.csv'
    )
  end

  private

    def check_remote_load
      params[:remote] ? false : 'application'
    end
end
