# encoding: utf-8

require 'csv'
require 'cgi'

class ReportsController < ApplicationController
  respond_to :html, :csv

  before_filter :authenticate_user!

  extend Reports::Helper
  include Reports::Helper

  def index
  end

  def send_data_csv(filename, report)
    send_data(
      report.to_csv,
      :type     => 'text/csv; charset=utf-8; header=present',
      :filename => filename
    )
  end
    
  @@feed_test_lose_aborts = false
  @@feed_test_lose_sub_details = false
  @@feed_use_counter = true
  
  def subfeeds
    specs = params[:specs]
    array = specs.split('/')
    centre = CGI.unescape array[0]
    column = CGI.unescape array[1]
    column = column.gsub(/^# /, "")
    raise "Invalid parameters (#{array.size})" if array.size != 2
    
    @title2 = "subfeeds: centre: '#{centre}' - column: '#{column}' (#{array.size})"

    @cached_report ||= feed_test_get_cached_report

    grouped_report = Grouping( @cached_report, :by => [ 'Production Centre'] )

    grouped_report = grouped_report[centre]
    grouped_report = Grouping( grouped_report, :by => [ 'Status'] )
    @report = grouped_report[column]
    
    column_names = [
        'Assigned - ES Cell QC In Progress Date',
        'Assigned - ES Cell QC Complete Date',
        'Micro-injection in progress Date',
        'Genotype confirmed Date',
        'Micro-injection aborted Date'
      ]
    
      column_names.each do |name|
        r1 = Regexp.new(column)
        next if r1.match(name)
        @report.remove_column(name) 
      end
      
      if @@feed_test_lose_sub_details
        @report.remove_column('Production Centre') 
        @report.remove_column('Status') 
        @report.remove_column('Assigned Date')
      end
     
      @report.remove_column('Sub-Project') 
      @report.remove_column('Consortium') 
      @report.remove_column('Priority') 

      @report.sort_rows_by!(["Gene"])

      if @@feed_use_counter  
        @report.add_column('Counter', :before => 'Gene')
        counter = 1
        @report.each do |row|
          row['Counter'] = counter
          counter += 1
        end
      end
      
      genes = []
      @report = Table(
        :data => @report.data,
        :column_names => @report.column_names,
#        :filters => lambda {|r| ! genes.include?(r['Gene']) && genes.push(r['Gene']) ? true : false }
        :filters => lambda {|r|
          if genes.include?(r['Gene'].downcase)
            return false
          end
        genes.push(r['Gene'].downcase)
        return true
        }
      )
    
  end

  def feed_test
    @report = feed_test_production_centre
  end

  def feed_test_get_cached_report   
    #get cached report
    detail_cache = ReportCache.find_by_name('mi_production_detail')
    raise 'cannot get cached report' if ! detail_cache
    
    #get string representing csv
    csv1 = detail_cache.csv_data
    raise 'cannot get cached report CSV' if ! csv1

    #build csv object
    csv2 = CSV.parse(csv1)
    raise 'cannot parse CSV' if ! csv2

    header = csv2.shift
    raise 'cannot get CSV header' if ! header

    #build ruport object
    table = Ruport::Data::Table.new :data => csv2, :column_names => header
    raise 'cannot build ruport instance from CSV' if ! table
    
    return table
  end

  def feed_test_clean_table2(table, filter=true)
    column_names = [
        '# Assigned - ES Cell QC In Progress',
        '# Assigned - ES Cell QC Complete',
        '# Micro-injection in progress',
        '# Genotype confirmed',
        '# Micro-injection aborted'
      ]
    
    report = Table(:data => table.data,
                    :column_names => table.column_names,
      :transforms => lambda {|r|
        column_names.each do |name|
          
          if r[name] == 0
            r[name] = ''
          else
            #tname = name.gsub(/\s+/, "_")
            #tname = tname.gsub(/\#/, "")
            tname = CGI.escape(name)
            cname = CGI.escape(r['Production Centre'])
            r[name] ="<a href='/feeds/list/#{cname}/#{tname}'>#{r[name]}</a>"
          end
          
        end
      },
      :filters => lambda {|r| ! filter || (r['Production Centre'] && r['Production Centre'].length > 0) }
    )
    report.remove_column('# Micro-injection aborted') if @@feed_test_lose_aborts
    return report
  end

  def feed_test_production_centre
    @cached_report ||= feed_test_get_cached_report
      
    report_table = Table(
      [
        'Production Centre',
        '# Assigned - ES Cell QC In Progress',
        '# Assigned - ES Cell QC Complete',
        '# Micro-injection in progress',
        '# Genotype confirmed',
        '# Micro-injection aborted'
      ]
    )

    grouped_report = Grouping( @cached_report, :by => [ 'Production Centre' ], :order => [:name]  )

    grouped_report.summary(
      'Production Centre',
      '# Assigned - ES Cell QC In Progress' => lambda { |group| count_unique_instances_of( group, 'Gene',
                lambda { |row| ((row.data['Status'] == 'Assigned - ES Cell QC In Progress')) ? true : false } ) },
      '# Assigned - ES Cell QC Complete' => lambda { |group| count_unique_instances_of( group, 'Gene',
                lambda { |row| ((row.data['Status'] == 'Assigned - ES Cell QC Complete')) ? true : false } ) },
      '# Micro-injection in progress' => lambda { |group| count_unique_instances_of( group, 'Gene',
                lambda { |row| ((row.data['Status'] == 'Micro-injection in progress')) ? true : false } ) },
      '# Genotype confirmed' => lambda { |group| count_unique_instances_of( group, 'Gene',
                lambda { |row| ((row.data['Status'] == 'Genotype confirmed')) ? true : false } ) },
      '# Micro-injection aborted' => lambda { |group| count_unique_instances_of( group, 'Gene',
                lambda { |row| ((row.data['Status'] == 'Micro-injection aborted')) ? true : false } ) }
    ).each do |row|
      report_table << {
        'Production Centre' => row['Production Centre'],
        '# Assigned - ES Cell QC In Progress' => row['# Assigned - ES Cell QC In Progress'],
        '# Assigned - ES Cell QC Complete' => row['# Assigned - ES Cell QC Complete'],
        '# Micro-injection in progress' => row['# Micro-injection in progress'],
        '# Genotype confirmed' => row['# Genotype confirmed'],
        '# Micro-injection aborted' => row['# Micro-injection aborted']
      }
    end
   
    report_table.sort_rows_by!( '# Genotype confirmed', :order => :descending )

    report = feed_test_clean_table2(report_table)
    return report
  end

  def double_assigned_plans_matrix
    @report = Reports::MiPlans::DoubleAssignment.get_matrix
    send_data_csv('double_assigned_matrix.csv', @report) if request.format == :csv
  end

  def double_assigned_plans_list
    @report = Reports::MiPlans::DoubleAssignment.get_list
    send_data_csv('double_assigned_list.csv', @report) if request.format == :csv
  end

  def double_assigned_plans
    @report1 = Reports::MiPlans::DoubleAssignment.get_matrix
    @report2 = Reports::MiPlans::DoubleAssignment.get_list
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

    Gene.order('marker_symbol asc').each do |gene|
      @report << {
        'Marker Symbol'     => gene.marker_symbol,
        'MGI Accession ID'  => gene.mgi_accession_id,
        '# IKMC Projects'   => gene.ikmc_projects_count,
        '# Clones'          => gene.pretty_print_types_of_cells_available.gsub('<br/>',' '),
        'Non-Assigned Plans'  => non_assigned_mis[gene.marker_symbol] ? non_assigned_mis[gene.marker_symbol].gsub('<br/>',' ') : nil,
        'Assigned Plans'      => assigned_mis[gene.marker_symbol] ? assigned_mis[gene.marker_symbol].gsub('<br/>',' ') : nil,
        'Aborted MIs'       => aborted_mis[gene.marker_symbol] ? aborted_mis[gene.marker_symbol].gsub('<br/>',' ') : nil,
        'MIs in Progress'   => mis_in_progress[gene.marker_symbol] ? mis_in_progress[gene.marker_symbol].gsub('<br/>',' ') : nil,
        'GLT Mice'          => glt_mice[gene.marker_symbol] ? glt_mice[gene.marker_symbol].gsub('<br/>',' ') : nil
      }
    end

    send_data(
      @report.to_csv,
      :type     => 'text/csv; charset=utf-8; header=present',
      :filename => 'genes_list.csv'
    )
  end

  def mi_attempts_list
    unless params[:commit].blank?
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

  def mi_attempts_monthly_production
    unless params[:commit].blank?
      @report = Reports::MonthlyProduction.generate(request, params)
      send_data_csv('mi_attempts_monthly_production.csv', @report) if request.format == :csv
    end
  end

  def mi_attempts_by_gene
    unless params[:commit].blank?
      @report = Reports::GeneSummary.generate(request, params)
      send_data_csv('mi_attempts_by_gene.csv', @report) if request.format == :csv
    end
  end

  def planned_microinjection_list
    @include_plans_with_active_attempts = true
    @include_plans_with_active_attempts = false if params[:include_plans_with_active_attempts] == 'false'

    unless params[:commit].blank?
      dup_params = params.dup
      dup_params.delete(:include_plans_with_active_attempts)
      @report = generate_planned_mi_list_report( dup_params, @include_plans_with_active_attempts )

      if @report.nil?
        redirect_to cleaned_redirect_params( :planned_microinjection_list, params ) if request.format == :csv
        return
      end

      @report.add_column('Reason for Inspect/Conflict') { |row| MiPlan.find(row.data['ID']).reason_for_inspect_or_conflict }
      @report.remove_columns(['ID'])

      mis_by_gene = {
        'Non-Assigned Plans' => Gene.pretty_print_non_assigned_mi_plans_in_bulk,
        'Assigned Plans'     => Gene.pretty_print_assigned_mi_plans_in_bulk,
        'Aborted MIs'      => Gene.pretty_print_aborted_mi_attempts_in_bulk,
        'MIs in Progress'  => Gene.pretty_print_mi_attempts_in_progress_in_bulk,
        'GLT Mice'         => Gene.pretty_print_mi_attempts_genotype_confirmed_in_bulk
      }

      mis_by_gene.each do |title,store|
        @report.add_column(title) do |row|
          data = store[row.data['Marker Symbol']]
          data.gsub!('<br/>',' ') if request.format == :csv and !data.nil?
          data
        end
      end

      @report = Grouping( @report, :by => params[:grouping], :order => proc {|i| i.name.to_s} ) unless params[:grouping].blank?

      if request.format == :csv
        send_data(
          @report.to_csv,
          :type     => 'text/csv; charset=utf-8; header=present',
          :filename => 'planned_microinjection_list.csv'
        )
      end
    end
  end

  def planned_microinjection_summary_and_conflicts
    @include_plans_with_active_attempts = true
    @include_plans_with_active_attempts = false if params[:include_plans_with_active_attempts] == 'false'

    unless params[:commit].blank?
      impc_consortia_ids = Consortium.where('name not in (?)', ['EUCOMM-EUMODIC','MGP-KOMP','UCD-KOMP']).map(&:id)

      all_mi_plans = generate_planned_mi_list_report({ :consortium_id => impc_consortia_ids }, @include_plans_with_active_attempts)
      all_mi_plans.sort_rows_by!('Consortium', :order => :ascending)

      mi_plans_grouped_by_consortia = Grouping( all_mi_plans, :by => ['Consortium'], :order => :name )

      total_number_of_planned_genes = MiPlan.where('consortium_id in (?)', impc_consortia_ids).without_active_mi_attempt.count(:gene_id, :distinct => true)
      if @include_plans_with_active_attempts
        total_number_of_planned_genes = MiPlan.where('consortium_id in (?)', impc_consortia_ids).count(:gene_id, :distinct => true)
      end

      ##
      ## Counts of mi_plans grouped by status
      ##

      statuses = MiPlanStatus.order('order_by asc').all.map { |s| s.name }
      summary_by_status_args = { :order => ['Consortium'] + statuses }
      statuses.each do |status|
        summary_by_status_args[status] = lambda { |group| count_unique_instances_of( group, 'Marker Symbol', lambda { |row| row.data['Status'] == status } ) }
      end

      @summary_by_status = mi_plans_grouped_by_consortia.summary( 'Consortium', summary_by_status_args )

      # Add totals by consortium
      @summary_by_status.add_column('TOTAL BY CONSORTIUM') { |row| statuses.map { |status| row[status] }.reduce(:+) }

      # Add totals by status
      gene_count_by_status =
        MiPlan.where('consortium_id in (?)', impc_consortia_ids).without_active_mi_attempt.count(
        :gene_id, :distinct => true, :group => :'mi_plan_statuses.name', :include => :mi_plan_status)

      if @include_plans_with_active_attempts
        gene_count_by_status =
          MiPlan.where('consortium_id in (?)', impc_consortia_ids).count(:gene_id, :distinct => true, :group => :'mi_plan_statuses.name', :include => :mi_plan_status)
      end

      @summary_by_status << totals = ['TOTAL BY STATUS'] + statuses.map { |status| gene_count_by_status[status] || 0 } + [total_number_of_planned_genes]

      ##
      ## Counts of mi_plans grouped by priority
      ##

      priorities = ['High','Medium','Low']
      summary_by_priority_args = { :order => ['Consortium'] + priorities }
      priorities.each do |priority|
        summary_by_priority_args[priority] =
          lambda { |group| count_unique_instances_of( group, 'Marker Symbol', lambda { |row| row.data['Priority'] == priority } ) }
      end

      @summary_by_priority = mi_plans_grouped_by_consortia.summary( 'Consortium', summary_by_priority_args )

      # Add totals by consortium
      @summary_by_priority.add_column('TOTAL BY CONSORTIUM') { |row| priorities.map { |priority| row[priority] }.reduce(:+) }

      # Add totals by priority
      gene_count_by_priority =
        MiPlan.where('consortium_id in (?)', impc_consortia_ids).without_active_mi_attempt.count(
        :gene_id, :distinct => true, :group => :'mi_plan_priorities.name', :include => :mi_plan_priority)

      if @include_plans_with_active_attempts
        gene_count_by_priority =
          MiPlan.where('consortium_id in (?)', impc_consortia_ids).count(:gene_id, :distinct => true, :group => :'mi_plan_priorities.name', :include => :mi_plan_priority)
      end

      @summary_by_priority << ['TOTAL BY PRIORITY'] + priorities.map { |priority| gene_count_by_priority[priority] || 0 } + [total_number_of_planned_genes]

      ##
      ## Counts of mi_plans grouped by status and priority
      ##

      @summary_by_status_and_priority = Table( ['Consortium', 'Status'] + priorities )

      mi_plans_grouped_by_status_consortia = Grouping( all_mi_plans, :by => ['Status','Consortium'] )
      mi_plans_grouped_by_status_consortia.each do |status|
        summary = mi_plans_grouped_by_status_consortia.subgrouping(status).summary( 'Consortium', summary_by_priority_args )
        summary.each_entry do |row|
          hash = row.to_hash
          hash['Status'] = status
          @summary_by_status_and_priority << hash
        end
      end

      @summary_by_status_and_priority = Grouping(
        @summary_by_status_and_priority,
        :by => ['Status'], :order => lambda { |g| MiPlanStatus.find_by_name!(g.name).order_by }
      )

      ##
      ## Details on conflicting and inspect mi_plans
      ##

      @conflict_report = all_mi_plans.sub_table { |row| row['Status'] == 'Conflict' }
      @conflict_report.add_column('Reason for Conflict') { |row| MiPlan.find(row.data['ID']).reason_for_inspect_or_conflict }
      @conflict_report.remove_columns(['ID','Status'])

      @inspect_report = all_mi_plans.sub_table { |row| row['Status'].include? 'Inspect' }
      @inspect_report.add_column('Reason for Inspect') { |row| MiPlan.find(row.data['ID']).reason_for_inspect_or_conflict }
      @inspect_report.remove_columns(['ID'])
      @inspect_report = Grouping( @inspect_report, :by => ['Status'], :order => lambda { |g| MiPlanStatus.find_by_name!(g.name).order_by } )

      if request.format == :csv
        response.headers['Content-Type'] = 'text/csv'
        response.headers['Content-Disposition'] = 'attachment; filename=planned_microinjection_summary_and_conflicts.csv'
      end

    end
  end

  def mi_production
    @detail_cache = ReportCache.find_by_name('mi_production_detail')
  end

  protected

  def generate_planned_mi_list_report( params={}, include_plans_with_active_attempts=false )
    report_column_order_and_names = {
      'id'                      => 'ID',
      'consortium.name'         => 'Consortium',
      'sub_project.name'        => 'SubProject',
      'production_centre.name'  => 'Production Centre',
      'gene.marker_symbol'      => 'Marker Symbol',
      'gene.mgi_accession_id'   => 'MGI Accession ID',
      'mi_plan_priority.name'   => 'Priority',
      'mi_plan_status.name'     => 'Status'
    }

    report_options = {
      :only       => report_column_order_and_names.keys,
      :conditions => process_filter_params( params ),
      :include    => {
        :sub_project        => { :only => [:name] },
        :consortium         => { :only => [:name] },
        :production_centre  => { :only => [:name] },
        :gene               => { :only => [:marker_symbol,:mgi_accession_id] },
        :mi_plan_priority   => { :only => [:name] },
        :mi_plan_status     => { :only => [:name] }
      }
    }

    report = case include_plans_with_active_attempts
    when true  then MiPlan.report_table( :all, report_options )
    when false then MiPlan.without_active_mi_attempt.report_table( :all, report_options )
    end

    return nil if report.size == 0

    report.remove_columns( report_column_order_and_names.dup.delete_if{ |key,value| !value.blank? }.keys )
    report.rename_columns( report_column_order_and_names.dup.delete_if{ |key,value| value.blank? } )
    report.sort_rows_by!('Marker Symbol', :order => :ascending)

    return report
  end

end
