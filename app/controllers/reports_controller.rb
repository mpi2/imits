# encoding: utf-8

require "#{Rails.root}/script/make_mmrrc_reports2.rb"

class ReportsController < ApplicationController
  respond_to :html, :csv

  before_filter :authenticate_user!, :except => [:impc_gene_list]

  layout :check_remote_load

  extend Reports::Helper
  include Reports::Helper

  def index
    @mmrrc_reports = MmrrcNew.new.get_files
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

    result = Gene.gene_production_summary()

    assigned_mis = Gene.pretty_print_assigned_mi_plans_in_bulk(:result => result['assigned plans'])
    non_assigned_mis = Gene.pretty_print_non_assigned_mi_plans_in_bulk(:result => result['non assigned plans'])
    mis_in_progress = Gene.pretty_print_mi_attempts_in_bulk_helper(:result => result['in progress mi attempts'])
    glt_mice = Gene.pretty_print_mi_attempts_in_bulk_helper(:result => result['genotype confirmed mi attempts'])
    aborted_mis = Gene.pretty_print_mi_attempts_in_bulk_helper(:result => result['aborted mi attempts'])
#    phenotype_attempts = Gene.pretty_print_phenotype_attempts_in_bulk_helper(:result => result['phenotype attempts'])

    Gene.find_by_sql("SELECT DISTINCT genes.* FROM genes LEFT JOIN mi_plans ON mi_plans.gene_id = genes.id WHERE genes.feature_type = 'protein coding gene' OR mi_plans.id IS NOT NULL ORDER BY genes.marker_symbol asc").each do |gene|
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

      options = {}
      options['consortia'] = params[:consortium_id].select{|id| !id.blank? }.map{|id| Consortium.find(id).name} if params.has_key?(:consortium_id) && params[:consortium_id].length > 0
      options['production_centres'] = params[:production_centre_id].select{|id| !id.blank? }.map{|id| Centre.find(id).name} if params.has_key?(:production_centre_id) && params[:production_centre_id].length > 0
      options['crispr'] = params[:crispr] if params.has_key?(:crispr)
      options['group'] = params[:grouping] if params.has_key?(:grouping)
      
      report_generator = MiAttemptListReport.new(options)

      @report = report_generator.mi_attempt_list
      @columns = {}
      report_generator.columns.each{|c, logic| @columns[c] = logic[:data] if logic[:show]}
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
