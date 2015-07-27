class V2::Reports::MiProductionController < ApplicationController

  before_filter :params_cleaned_for_search, :only => [:gene_production_detail, :mi_plan_production_detail, :centre_and_consortia_production_detail, :consortia_production_detail, :centre_production_detail]

  before_filter :authenticate_user!, :except => [:production_detail, :gene_production_detail, :consortia_production_detail, :mgp_production_by_subproject, :mgp_production_by_priority]
  before_filter :authenticate_user_if_not_sanger, :only => [:production_detail, :gene_production_detail, :consortia_production_detail, :mgp_production_by_subproject, :mgp_production_by_priority]

  helper :reports

  before_filter do
    if params[:format] == 'csv'
      response.headers["Cache-Control"] = "no-cache"
      response.headers["Content-Type"] = "text/csv"
      response.headers["Content-Disposition"] = "attachment;filename=#{action_name}-#{Date.today.to_s(:db)}.csv"
    end
  end

  def gene_production_detail
    category = params[:category]
    params[:q].delete("category")
    @approach = 'all' if @approach.blank?

    @intermediate_table = IntermediateReportSummaryByGene.new
    @intermediate_report = ActiveRecord::Base.connection.execute(IntermediateReportSummaryByGene.where_sql(category, @approach, nil, params[:q]))
    render :template => 'v2/reports/mi_production/production_detail'
  end

  def mi_plan_production_detail
    category = params[:category]
    params[:q].delete("category")
    @approach = 'all' if @approach.blank?

    @intermediate_table = IntermediateReportSummaryByMiPlan.new
    @intermediate_report = ActiveRecord::Base.connection.execute(IntermediateReportSummaryByMiPlan.where_sql(category, @approach, nil, params[:q]))
  end

  def centre_and_consortia_production_detail
    category = params[:category]
    params[:q].delete("category")
    @approach = 'all' if @approach.blank?

    @intermediate_table = IntermediateReportSummaryByCentreAndConsortia.new
    @intermediate_report = ActiveRecord::Base.connection.execute(IntermediateReportSummaryByCentreAndConsortia.where_sql(category, @approach, nil, params[:q]))
    render :template => 'v2/reports/mi_production/production_detail'
  end

  def consortia_production_detail
    category = params[:category]
    params[:q].delete("category")
    @approach = 'all' if @approach.blank?

    @intermediate_table = IntermediateReportSummaryByConsortia.new
    @intermediate_report = ActiveRecord::Base.connection.execute(IntermediateReportSummaryByConsortia.where_sql(category, @approach, nil, params[:q]))
    render :template => 'v2/reports/mi_production/production_detail'
  end

  def centre_production_detail
    category = params[:category]
    params[:q].delete("category")
    @approach = 'all' if @approach.blank?

    @intermediate_table = IntermediateReportSummaryByCentre.new
    @intermediate_report = ActiveRecord::Base.connection.execute(IntermediateReportSummaryByCentre.where_sql(category, approach, nil, params[:q]))
    render :template => 'v2/reports/mi_production/production_detail'
  end

  def komp2_production_summary
    report_filters

    @title = Komp2ProductionReport.title

    @report = Komp2ProductionReport.new({'category' => @category, 'allele_type' => @allele_type})
    @consortium_by_distinct_gene = @report.consortium_by_distinct_gene
    @consortium_by_status        = @report.generate_consortium_by_status
    @consortium_centre_by_status = @report.generate_consortium_centre_by_status
    @consortium_centre_by_tm1b_phenotyping_status     = @report.generate_consortium_centre_by_phenotyping_status(cre_excision_required = true)
    @consortium_centre_by_tm1a_phenotyping_status = @report.generate_consortium_centre_by_phenotyping_status(cre_excision_required = false)
    @distribution_centre_counts = @report.generate_distribution_centre_counts
    @phenotyping_counts = @report.generate_phenotyping_counts
    @gene_efficiency_totals      = @report.generate_gene_efficiency_totals
    @clone_efficiency_totals     = @report.generate_clone_efficiency_totals
    @effort_efficiency_totals     = @report.generate_effort_efficiency_totals
    @crispr_effort_efficiency_totals = @report.generate_crispr_efficiency_totals
    @mi_plan_statuses = Komp2ProductionReport.mi_plan_statuses

    render :template => 'v2/reports/mi_production/production_summary'
  end

  def impc_production_summary
    report_filters

    @title = ImpcProductionReport.title
    @report = ImpcProductionReport.new({'category' => @category, 'allele_type' => @allele_type})
    @consortium_by_distinct_gene = @report.consortium_by_distinct_gene
    @consortium_by_status        = @report.generate_consortium_by_status
    @consortium_centre_by_status = @report.generate_consortium_centre_by_status
    @consortium_centre_by_tm1b_phenotyping_status     = @report.generate_consortium_centre_by_phenotyping_status(cre_excision_required = true)
    @consortium_centre_by_tm1a_phenotyping_status = @report.generate_consortium_centre_by_phenotyping_status(cre_excision_required = false)
    @distribution_centre_counts = @report.generate_distribution_centre_counts
    @phenotyping_counts = @report.generate_phenotyping_counts
    @gene_efficiency_totals      = @report.generate_gene_efficiency_totals
    @clone_efficiency_totals     = @report.generate_clone_efficiency_totals
    @effort_efficiency_totals     = @report.generate_effort_efficiency_totals
    @crispr_effort_efficiency_totals = @report.generate_crispr_efficiency_totals
    @mi_plan_statuses = ImpcProductionReport.mi_plan_statuses

    render :template => 'v2/reports/mi_production/production_summary'
  end

  def eucomm_tools_production_summary
    report_filters

    @title = EucommToolsProductionReport.title
    @report = EucommToolsProductionReport.new({'category' => @category, 'allele_type' => @allele_type})
    @consortium_by_distinct_gene = @report.consortium_by_distinct_gene
    @consortium_by_status        = @report.generate_consortium_by_status
    @consortium_centre_by_status = @report.generate_consortium_centre_by_status
    @consortium_centre_by_tm1b_phenotyping_status = @report.generate_consortium_centre_by_phenotyping_status(cre_excision_required = true)
    @consortium_centre_by_tm1a_phenotyping_status = @report.generate_consortium_centre_by_phenotyping_status(cre_excision_required = false)
    @distribution_centre_counts = @report.generate_distribution_centre_counts
    @phenotyping_counts = @report.generate_phenotyping_counts
    @gene_efficiency_totals      = @report.generate_gene_efficiency_totals
    @clone_efficiency_totals     = @report.generate_clone_efficiency_totals
    @effort_efficiency_totals     = @report.generate_effort_efficiency_totals
    @crispr_effort_efficiency_totals = @report.generate_crispr_efficiency_totals
    @mi_plan_statuses = EucommToolsProductionReport.mi_plan_statuses

    render :template => 'v2/reports/mi_production/production_summary'
  end

  def mgp_production_by_subproject
    @report  = SubProjectReport.new
    @columns = SubProjectReport.columns

    @status_by_sub_project = @report.report_hash
  end

  def mgp_production_by_priority
    @report  = PriorityReport.new
    @columns = PriorityReport.columns

    @status_by_priority = @report.report_hash
  end

  def komp2_summary_by_month
    report_filters
    @report  = Komp2SummaryByMonthReport.new(nil, @category, @approach, @allele_type)
    @clone_columns = @report.clone_columns
    @phenotype_columns = @report.phenotype_columns
    @consortia = @report.available_consortia

    @summary_by_month = @report.report_hash
  end

  def impc_summary_by_month
    report_filters
    @report  = ImpcSummaryByMonthReport.new(nil, @category, @approach, @allele_type)
    @clone_columns = @report.clone_columns
    @phenotype_columns = @report.phenotype_columns
    @consortia = @report.available_consortia

    @summary_by_month = @report.report_hash
  end

  def komp2_graph_report_display
    report_filters
    @title = 'KOMP Production Summaries'
    @report = Komp2GraphReportDisplay.new(nil, @category, @approach, @allele_type)
    date = @report.date_previous_month.to_date.at_beginning_of_month
    @consortia = @report.available_consortia
    @date = date.to_s
    @date_name = Date::ABBR_MONTHNAMES[date.month]
  end

  def graph_report_display

    report_filters
    @consortia = params[:consortia].split(',').map{|con| Consortium.find_by_name(con).try(:name)}.reject { |c| c.blank? }
    @title = "Production Summaries for #{@consortia.to_sentence}"

    @error = false
    missing_consortia = []
    error_message = 'The following consortia do not exist: '
    @consortia.each do |consortium|
      if !Consortium.find_by_name(consortium)
        missing_consortia.append(consortium)
        @error = true
      end
    end
    error_message << missing_consortia.to_sentence


    if ! @error
      @report = GraphReportDisplay.new(@consortia, @category, @approach, @allele_type)
      date = @report.date_previous_month.to_date.at_beginning_of_month
      @date = date.to_s
      @date_name = Date::ABBR_MONTHNAMES[date.month]
    else
      flash.now[:alert] = error_message
      @consortia = []
    end
    render :template => 'v2/reports/mi_production/komp2_graph_report_display'
  end

  def graph_report_display_image
    filename = params[:chart_file_name].split('/').pop
    charts_folder = File.join(Rails.application.config.paths['tmp'].first, "reports/impc_graph_report_display/charts")
    file_path = File.join(charts_folder, filename)

    data = File.read(file_path)
    response.headers["Cache-Control"] = "no-cache"
    send_data data,
    :filename => filename,
    :type => 'image/jpeg',
    :disposition => 'inline'
  end

  def graph_report_download_image
    filename = params[:chart_file_name].split('/').pop
    charts_folder = File.join(Rails.application.config.paths['tmp'].first, "reports/impc_graph_report_display/charts")
    file_path = File.join(charts_folder, filename)
    if File.exists?(file_path)
      data = File.read(file_path)
      response.headers["Cache-Control"] = "no-cache"
      send_data data,
      :filename => filename,
      :type => 'image/jpeg'
    else
      flash[:alert] = "Page expired! Please try again"
      redirect_to :action => 'komp2_graph_report_display'

    end
  end


  def impc_centre_by_month
    report_filters

    @report = ImpcCentreByMonthReport.new({'category' => @category})
    @centre_by_month = @report.report_rows
    @cumulative_totals = @report.cumulative_totals
    @consortia = @report.consortia
    @columns = ImpcCentreByMonthReport.columns.dup
    if @category == 'crispr'
      @columns.delete('Injected')
    else
      @columns.delete(' Injected')
    end
    @es_cell_columns = ImpcCentreByMonthReport.es_cell_supply_columns
  end

  def impc_centre_by_month_consortia_breakdown
    @centre = Centre.find_by_name(params[:centre]).try(:name) || ''
    if @centre.blank?
      flash[:alert] = "Invalid Production Centre"
    end
    @report = ImpcCentreByMonthReportConsortiaBreakdown.new(@centre)
    @consortia = @report.consortia
    @consortium_by_month = @report.report_rows
    @cumulative_totals = @report.cumulative_totals
    @columns = ImpcCentreByMonthReport.columns
    @es_cell_columns = ImpcCentreByMonthReport.es_cell_supply_columns
  end

  def impc_centre_es_detail
    @report = ImpcCentreByMonthDetail.new
  end

  def impc_centre_mi_detail
    @report = ImpcCentreByMonthDetail.new
    @centre = params[:centre]
    @mis = @report.mi_rows(@centre)
  end

  def planned_microinjection_list
    if !params[:commit].blank?
      consortium = Consortium.find_by_name(params[:consortium]).try(:name)

      @report = PlannedMicroinjectionList.new
      @mi_plan_summary = @report.mi_plan_summary(consortium)
      @pretty_print_non_assigned_mi_plans = @report.pretty_print_non_assigned_mi_plans
      @pretty_print_assigned_mi_plans = @report.pretty_print_assigned_mi_plans
      @pretty_print_aborted_mi_attempts = @report.pretty_print_aborted_mi_attempts
      @pretty_print_mi_attempts_in_progress= @report.pretty_print_mi_attempts_in_progress
      @pretty_print_mi_attempts_genotype_confirmed = @report.pretty_print_mi_attempts_genotype_confirmed
      @consortium = consortium.blank? ? 'All' : consortium
      @count = @report.blank? ? 0 : @mi_plan_summary.count
    end
  end

  def planned_crispr_microinjection_list
    @report = PlannedMicroinjectionList.new({:crisprs => true, :show_eucommtoolscre_data => false})
    @mi_plan_summary = @report.mi_plan_summary(nil)
    @pretty_print_non_assigned_mi_plans = @report.pretty_print_non_assigned_mi_plans
    @pretty_print_assigned_mi_plans = @report.pretty_print_assigned_mi_plans
    @pretty_print_aborted_mi_attempts = @report.pretty_print_aborted_mi_attempts
    @pretty_print_mi_attempts_in_progress= @report.pretty_print_mi_attempts_in_progress
    @pretty_print_mi_attempts_genotype_confirmed = @report.pretty_print_mi_attempts_genotype_confirmed
    @consortium = 'All'
    @count = @report.blank? ? 0 : @mi_plan_summary.count
  end

  def notifications_by_gene
    notifications_by_gene_cache
    #notifications_by_gene_live
  end

  def notifications_by_gene_cache
    if ! params[:commit].blank?
      consortium = Consortium.find_by_name(params[:consortium]).try(:name)
      production_centre = nil
      consortium = params[:consortium] if ! consortium

      format = 'csv' if request.format == :csv
      format = 'html' if request.format == :html

      @report = ReportCache.find_by_name_and_format('notifications_by_gene_' + consortium.to_s, format)

      @report.data.gsub!(/\n\n/, "\n")

      if request.format == :csv
        send_data @report.data,
        :type => 'text/csv; charset=iso-8859-1; header=present',
        :disposition => "attachment; filename=notifications_by_gene-#{Time.now.strftime('%d-%m-%y--%H-%M')}.csv"
        return
      end
    end

    @title = 'Notification interest by gene'
    render :template => 'v2/reports/mi_production/notifications_by_gene_cache'
  end

  def notifications_by_gene_live
    if !params[:commit].blank?
      consortium = Consortium.find_by_name(params[:consortium]).try(:name)
      show_eucommtoolscre_data = false
      show_eucommtoolscre_data = true if consortium == 'EUCOMMToolsCre'
      production_centre = Centre.find_by_name(params[:production_centre]).try(:name)
      consortium = params[:consortium] if ! consortium

      @report = NotificationsByGene.new({:show_eucommtoolscre_data => show_eucommtoolscre_data})
      @mi_plan_summary = @report.mi_plan_summary(production_centre, consortium)
      @pretty_print_non_assigned_mi_plans = @report.pretty_print_non_assigned_mi_plans
      @pretty_print_assigned_mi_plans = @report.pretty_print_assigned_mi_plans
      @pretty_print_aborted_mi_attempts = @report.pretty_print_aborted_mi_attempts
      @pretty_print_mi_attempts_in_progress= @report.pretty_print_mi_attempts_in_progress
      @pretty_print_mi_attempts_genotype_confirmed = @report.pretty_print_mi_attempts_genotype_confirmed
      @pretty_print_types_of_cells_available = @report.pretty_print_types_of_cells_available
      @production_centre = production_centre.blank? ? '' : production_centre
      @consortium = consortium.blank? ? '' : consortium
      @blurb = ""
      @blurb = "#{consortium} " if ! consortium.blank?
      @blurb += "#{production_centre}" if ! production_centre.blank?
      @blurb = "All" if consortium.blank? && production_centre.blank?
      @count = @report.blank? ? 0 : @mi_plan_summary.count
#      @pretty_print_statuses = @report.pretty_print_statuses
    end
    @title = 'Notification interest by gene'
    render :template => 'v2/reports/mi_production/notifications_by_gene_live'
  end

  def notifications_by_gene_for_idg
    notifications_by_gene_for_idg_cache
    #notifications_by_gene_for_idg_live
  end

  def notifications_by_gene_for_idg_live
    consortium = Consortium.find_by_name(params[:consortium]).try(:name)
    show_eucommtoolscre_data = false
    show_eucommtoolscre_data = true if consortium == 'EUCOMMToolsCre'
    production_centre = Centre.find_by_name(params[:production_centre]).try(:name)

    @report = NotificationsByGene.new({:crispr => true, :show_eucommtoolscre_data => show_eucommtoolscre_data})
    @mi_plan_summary = @report.mi_plan_summary(production_centre, consortium)
    @pretty_print_non_assigned_mi_plans = @report.pretty_print_non_assigned_mi_plans
    @pretty_print_assigned_mi_plans = @report.pretty_print_assigned_mi_plans
    @pretty_print_aborted_mi_attempts = @report.pretty_print_aborted_mi_attempts
    @pretty_print_mi_attempts_in_progress= @report.pretty_print_mi_attempts_in_progress
    @pretty_print_mi_attempts_genotype_confirmed = @report.pretty_print_mi_attempts_genotype_confirmed
    @pretty_print_types_of_cells_available = @report.pretty_print_types_of_cells_available
    @production_centre = production_centre.blank? ? '' : production_centre
    @consortium = consortium.blank? ? '' : consortium
    @blurb = ""
    @blurb = "#{consortium} " if ! consortium.blank?
    @blurb += "#{production_centre}" if ! production_centre.blank?
    @blurb = "All" if consortium.blank? && production_centre.blank?
    @count = @report.blank? ? 0 : @mi_plan_summary.count
#    @pretty_print_statuses = @report.pretty_print_statuses
    params[:commit] = true

    @title = 'IDG Gene List Activity'
    render :template => 'v2/reports/mi_production/notifications_by_gene_live'
  end

  def notifications_by_gene_for_idg_cache
    consortium = Consortium.find_by_name(params[:consortium]).try(:name)
    production_centre = nil
    params[:commit] = true

    format = 'csv' if request.format == :csv
    format = 'html' if request.format == :html

    @report = ReportCache.find_by_name_and_format('notifications_by_gene_for_idg_' + consortium.to_s, format)

    @report.data.gsub!(/\n\n/, "\n")

    if request.format == :csv
      send_data @report.data,
      :type => 'text/csv; charset=iso-8859-1; header=present',
      :disposition => "attachment; filename=notifications_by_gene_for_idg-#{Time.now.strftime('%d-%m-%y--%H-%M')}.csv"
      return
    end

    @title = 'IDG Gene List Activity'
    render :template => 'v2/reports/mi_production/notifications_by_gene_cache'
  end

  def impc_centre_pa_detail
    @report = ImpcCentreByMonthDetail.new
    @centre = params[:centre]
    @pas = @report.pa_rows(@centre)
  end

  def genes_gt_mi_attempt_summary
    params[:consortia] = [] if !params.has_key?(:consortia)
    params[:centres] = [] if !params.has_key?(:centres)
    @consortia = Consortium.where(:name => params[:consortia].split(','))
    @production_centres = Centre.where(:name => params[:centres].split(','))

    @title = ''
    @report = BaseProductionReport.new
    @report.class.available_consortia = @consortia.map(&:name)
    @report.class.available_production_centres = @production_centres.map(&:name)
    @micro_injection_list = @report.most_advanced_gt_mi_for_genes

    render :template => 'v2/reports/mi_production/mi_attempt_summary'
  end

  def all_mi_attempt_summary
    @consortia = Consortium.where(:name => params[:consortia].split(','))
    @production_centres = Centre.where(:name => params[:centres].split(','))

    @title = ''
    @report = BaseProductionReport.new
    @report.class.available_consortia = @consortia.map(&:name)
    @report.class.available_production_centres = @production_centres.map(&:name)
    @micro_injection_list = @report.micro_injection_list

    render :template => 'v2/reports/mi_production/mi_attempt_summary'
  end

  def sliding_efficiency
    @consortium_name = params[:consortium] || params[:consortium_name] || params[:consortia]
    @production_centre_name = params[:centre] || params[:production_centre_name] || params[:centre_name]

    @category = params[:category || 'es cell']

    @report = SlidingEfficiencyReport.new(@category, @consortium_name, @production_centre_name)

    bpr = BaseProductionReport.new
    bpr.class.available_consortia = [@consortium_name]
    @effort_efficiency_totals = bpr.effort_efficiency_totals

  end

  private

  def report_filters
    @category = !params[:category].blank? && ['crispr', 'es cell', 'all'].include?(params[:category]) ? params[:category] : 'es cell'
    @approach = !params[:approach].blank? && ['micro injection', 'mouse allele modification'].include?(params[:approach]) ? params[:approach] : 'all'
    @allele_type = !params[:allele_type].nil? && TargRepRealAllele.types.include?(params[:allele_type]) ? params[:allele_type] : nil
  end

  def params_cleaned_for_search
    new_params = params.dup
    params[:q] ||= {}
    new_params = new_params.delete_if {|k| ['controller', 'action', 'format', 'page', 'per_page', 'utf8', '_dc'].include? k }
    params[:q].merge!(new_params)

    ## Remap param keys based on #translated_param_keys
    params[:q] = Hash[params[:q].map {|key, value| [translated_param_keys[key] || key, value] }]
    translated_param_keys.keys.each {|k| params.delete(k)}

    translate_param_values(params[:q])
  end

  def translated_param_keys

    return {
     'gene'                                   => 'gene_eq',
     'mgi_accession_id'                       => 'mgi_accession_id_eq',
     'consortium'                             => 'consortium_eq',
     'production_centre'                      => 'production_centre_eq',
     'pcentre'                                => 'production_centre_eq',
     'mi_plan_status'                         => 'mi_plan_status_eq',
     'mi_attempt_status'                      => 'mi_attempt_status_eq',
     'mouse_allele_mod_status'                => 'mouse_allele_mod_status_eq',
     'phenotyping_status'                     => 'phenotyping_status_eq'
    }
  end

  def translate_param_values(hash)
    if hash['no_limit']
      lower_limit = true
    else
      lower_limit = false
    end
    if hash['type'].to_s.downcase == 'es cell qc'
      hash['mi_plan_status_in'] = ['Assigned - ES Cell QC Complete', 'Assigned - ES Cell QC In Progress', 'Aborted - ES Cell QC Failed']
      translate_date(hash, hash['mi_plan_status_eq'], lower_limit)

    elsif ['gene interest', 'cumulative gene interest'].include?(hash['type'].to_s.downcase)
      translate_date(hash, 'gene_interest_date', lower_limit)

    elsif ['es qc confirmed', 'es cell qc complete', 'cumulative es cell qc complete'].include?(hash['type'].to_s.downcase)
      hash['mi_plan_status_eq'] = 'Assigned - ES Cell QC Complete'
      translate_date(hash, hash['mi_plan_status_eq'], lower_limit)

    elsif ['es cell qc in progress', 'cumulative es starts'].include?(hash['type'].to_s.downcase)
      hash['mi_plan_status_eq'] = 'Assigned - ES Cell QC In Progress'
      translate_date(hash, hash['mi_plan_status_eq'], lower_limit)

    elsif ['es cell qc failed', 'es qc failed', 'cumulative es cell qc failed'].include?(hash['type'].to_s.downcase)
      hash['mi_plan_status_eq'] = 'Aborted - ES Cell QC Failed'
      translate_date(hash, hash['mi_plan_status_eq'], lower_limit)

    elsif hash['type'].to_s.downcase == 'microinjections'
      hash['mi_attempt_status_nnull'] = 1
      translate_date(hash, 'Micro-injection in progress', lower_limit)

    elsif ['micro-injection in progress', 'cumulative mis'].include?(hash['type'].to_s.downcase)
      hash['mi_attempt_status_eq'] = 'Micro-injection in progress'
      translate_date(hash, hash['mi_attempt_status_eq'], lower_limit)

    elsif ['chimaeras produced', 'chimeras obtained', 'chimeras'].include?(hash['type'].to_s.downcase)
      hash['mi_attempt_status_eq'] = 'Chimeras obtained'
      translate_date(hash, hash['mi_attempt_status_eq'], lower_limit)

    elsif ['founders produced', 'founders obtained', 'founders'].include?(hash['type'].to_s.downcase)
      hash['mi_attempt_status_eq'] = 'Founder obtained'
      translate_date(hash, hash['mi_attempt_status_eq'], lower_limit)

    elsif ['genotype confirmed mice', 'genotype confirmed', 'cumulative genotype confirmed'].include?(hash['type'].to_s.downcase)
      hash['mi_attempt_status_eq'] = 'Genotype confirmed'
      translate_date(hash, hash['mi_attempt_status_eq'], lower_limit)

    elsif ['microinjection aborted', 'micro-injection aborted'].include?(hash['type'].to_s.downcase)
      hash['mi_attempt_status_eq'] = 'Micro-injection aborted'
      translate_date(hash, hash['mi_attempt_status_eq'], lower_limit)

#    elsif ['phenotype attempt registered', 'cumulative phenotype registered'].include?(hash['type'].to_s.downcase)
#      hash['mouse_allele_mod_status_eq'] = 'Phenotype Attempt Registered'
#      translate_date(hash, hash['mouse_allele_mod_status_eq'], lower_limit)

#    elsif ['intent to phenotype', 'registered for phenotyping'].include?(hash['type'].to_s.downcase)
#      hash['mouse_allele_mod_status_ci_in'] = ['Phenotype Attempt Registered', 'Rederivation Started', 'Rederivation Complete', 'Cre Excision Started', 'Cre Excision Complete', 'Phenotyping Started', 'Phenotyping Complete', 'Phenotype Attempt Aborted']
#      translate_date(hash, 'Phenotype Attempt Registered', lower_limit)

    elsif hash['type'].to_s.downcase == 'rederivation started'
      hash['mouse_allele_mod_status_eq'] = 'Rederivation Started'
      translate_date(hash, hash['mouse_allele_mod_status_eq'], lower_limit)

    elsif hash['type'].to_s.downcase == 'rederivation completed'
      hash['mouse_allele_mod_status_eq'] = 'Rederivation Complete'
      translate_date(hash, hash['mouse_allele_mod_status_eq'], lower_limit)

    elsif hash['type'].to_s.downcase == 'cre excision started'
      hash['mouse_allele_mod_status_eq'] = 'Cre Excision Started'
      translate_date(hash, hash['mouse_allele_mod_status_eq'], lower_limit)

    elsif ['cre excision completed', 'cre excision complete', 'cumulative cre excision complete'].include?(hash['type'].to_s.downcase)
      hash['mouse_allele_mod_status_eq'] = 'Cre Excision Complete'
      translate_date(hash, hash['mouse_allele_mod_status_eq'], lower_limit)

    elsif ['phenotyping started', 'cumulative phenotype started'].include?(hash['type'].to_s.downcase)
      hash['phenotyping_status_eq'] = 'Phenotyping Started'
      translate_date(hash, hash['phenotyping_status_eq'], lower_limit)

    elsif ['phenotyping experiments started', 'cumulative phenotyping experiments started'].include?(hash['type'].to_s.downcase)
      hash['phenotyping_experiments_started_date_nnull'] = "1"
      translate_date(hash, 'Phenotyping Experiments Started', lower_limit)

    elsif ['tm1a phenotype experiments started'].include?(hash['type'].to_s.downcase)
      @approach = 'micro-injection'
      hash['phenotyping_experiments_started_date_nnull'] = "1"
      translate_date(hash, 'Phenotyping Experiments Started', lower_limit)

    elsif ['tm1b phenotype experiments started'].include?(hash['type'].to_s.downcase)
      @approach = 'mouse allele modification'
      hash['phenotyping_experiments_started_date_nnull'] = "1"
      translate_date(hash, 'Phenotyping Experiments Started', lower_limit)

    elsif ['phenotyping completed', 'phenotyping complete', 'cumulative phenotype complete'].include?(hash['type'].to_s.downcase)
      hash['phenotyping_status_eq'] = 'Phenotyping Complete'
      translate_date(hash, hash['phenotyping_status_eq'], lower_limit)

#    elsif ['phenotyping aborted', 'phenotype attempt aborted'].include?(hash['type'].to_s.downcase)
#      hash['phenotyping_status_eq'] = 'Phenotype Attempt Aborted'
#      translate_date(hash, hash['phenotyping_status_eq'], lower_limit)

    elsif ['genotype confirmed mice 6 months'].include?(hash['type'].to_s.downcase)
      hash['mi_attempt_status_eq'] = 'Genotype confirmed'
      hash['genotype_confirmed_date_gteq'] = 6.months.ago.to_date

    elsif ['microinjection aborted 6 months'].include?(hash['type'].to_s.downcase)
      hash['mi_attempt_status_eq'] = 'Micro-injection aborted'
      hash['micro_injection_aborted_date_gteq'] = 6.months.ago.to_date

    elsif ['tm1b phenotype attempt registered', 'cumulative tm1b phenotype registered'].include?(hash['type'].to_s.downcase)
      @approach = 'mouse allele modification'
      hash['phenotyping_status_eq'] = 'Phenotype Attempt Registered'
      translate_date(hash, hash['phenotyping_status_eq'], lower_limit)

    elsif ['tm1b intent to phenotype'].include?(hash['type'].to_s.downcase)
      @approach = 'mouse allele modification'
      hash['mouse_allele_mod_status_nnull'] = 1
      translate_date(hash, 'Phenotyping Production Registered', lower_limit)

    elsif ['tm1b intent to excise'].include?(hash['type'].to_s.downcase)
      @approach = 'mouse allele modification'
      hash['phenotyping_status_nnull'] = 1
      translate_date(hash, 'Phenotyping Production Registered', lower_limit)

    elsif hash['type'].to_s.downcase == 'tm1b rederivation started'
      @approach = 'mouse allele modification'
      hash['mouse_allele_mod_status_eq'] = 'Rederivation Started'
      translate_date(hash, hash['mouse_allele_mod_status_eq'], lower_limit)

    elsif hash['type'].to_s.downcase == 'tm1b rederivation completed'
      @approach = 'mouse allele modification'
      hash['mouse_allele_mod_status_eq'] = 'Rederivation Complete'
      translate_date(hash, hash['mouse_allele_mod_status_eq'], lower_limit)

    elsif hash['type'].to_s.downcase == 'tm1b cre excision started'
      @approach = 'mouse allele modification'
      hash['mouse_allele_mod_status_eq'] = 'Cre Excision Started'
      translate_date(hash, hash['mouse_allele_mod_status_eq'], lower_limit)

    elsif ['tm1b cre excision completed', 'tm1b cre excision complete', 'cumulative tm1b cre excision complete'].include?(hash['type'].to_s.downcase)
      @approach = 'mouse allele modification'
      hash['mouse_allele_mod_status_eq'] = 'Cre Excision Complete'
      translate_date(hash, hash['mouse_allele_mod_status_eq'], lower_limit)

    elsif hash['type'].to_s.downcase == 'tm1b phenotyping started'
      @approach = 'mouse allele modification'
      hash['phenotyping_status_eq'] = 'Phenotyping Started'
      translate_date(hash, hash['phenotyping_status_eq'], lower_limit)

    elsif ['tm1b phenotyping completed', 'tm1b phenotyping complete', 'cumulative tm1b phenotype complete'].include?(hash['type'].to_s.downcase)
      @approach = 'mouse allele modification'
      hash['phenotyping_status_eq'] = 'Phenotyping Complete'
      translate_date(hash, hash['phenotyping_status_eq'], lower_limit)

    elsif ['tm1b phenotyping aborted', 'tm1b phenotype attempt aborted'].include?(hash['type'].to_s.downcase)
      @approach = 'mouse allele modification'
      hash['phenotyping_status_eq'] = 'Phenotype Production Aborted'
      translate_date(hash, hash['phenotyping_status_eq'], lower_limit)

    elsif ['tm1a phenotype attempt registered', 'cumulative tm1a phenotype registered'].include?(hash['type'].to_s.downcase)
      @approach = 'micro-injection'
      hash['phenotyping_status_eq'] = 'Phenotype Attempt Registered'
      translate_date(hash, hash['phenotyping_status_eq'], lower_limit)

    elsif ['tm1a intent to phenotype'].include?(hash['type'].to_s.downcase)
      @approach = 'micro-injection'
      hash['phenotyping_status_nnull'] = 1
      translate_date(hash, 'Phenotype Attempt Registered', lower_limit)

    elsif hash['type'].to_s.downcase == 'tm1a rederivation started'
      @approach = 'micro-injection'
      hash['phenotyping_status_eq'] = 'Rederivation Started'
      translate_date(hash, hash['phenotyping_status_eq'], lower_limit)

    elsif hash['type'].to_s.downcase == 'tm1a rederivation completed'
      @approach = 'micro-injection'
      hash['phenotyping_status_eq'] = 'Rederivation Complete'
      translate_date(hash, hash['phenotyping_status_eq'], lower_limit)

    elsif hash['type'].to_s.downcase == 'tm1a phenotyping started'
      @approach = 'micro-injection'
      hash['phenotyping_status_eq'] = 'Phenotyping Started'
      translate_date(hash, hash['phenotyping_status_eq'], lower_limit)

    elsif ['tm1a phenotyping completed', 'tm1a phenotyping complete', 'cumulative tm1a phenotype complete'].include?(hash['type'].to_s.downcase)
      @approach = 'micro-injection'
      hash['phenotyping_status_eq'] = 'Phenotyping Complete'
      translate_date(hash, hash['phenotyping_status_eq'], lower_limit)

    elsif ['tm1a phenotyping aborted', 'tm1a phenotype attempt aborted'].include?(hash['type'].to_s.downcase)
      @approach = 'micro-injection'
      hash['phenotyping_status_eq'] = 'Phenotype Production Aborted'
      translate_date(hash, hash['phenotyping_status_eq'], lower_limit)

#    elsif hash['type'].to_s.downcase == 'tm1b phenotype attempt mi attempt plan confliction'
#      @approach = 'mouse allele modification'
#      hash['phenotype_attempt_status_ci_in'] = ['Phenotype Attempt Registered', 'Rederivation Started', 'Rederivation Complete', 'Cre Excision Started', 'Cre Excision Complete', 'Phenotyping Started', 'Phenotyping Complete', 'Phenotype Attempt Aborted']
#      hash['tm1b_mi_attempt_consortium_or_tm1b_mi_attempt_production_centre_not_in'] = [params[:q]['consortium_eq'],params[:q]['production_centre_eq']]

#    elsif hash['type'].to_s.downcase == 'tm1a phenotype attempt mi attempt plan confliction'
#      @approach = 'micro-injection'
#      hash['phenotype_attempt_status_ci_in'] = ['Phenotype Attempt Registered', 'Rederivation Started', 'Rederivation Complete', 'Cre Excision Started', 'Cre Excision Complete', 'Phenotyping Started', 'Phenotyping Complete', 'Phenotype Attempt Aborted']
#      hash['tm1a_mi_attempt_consortium_or_tm1a_mi_attempt_production_centre_not_in'] = [params[:q]['consortium_eq'],params[:q]['production_centre_eq']]
    end

    ##
    ## We only want to filter by date if included in query.
    ## This is so we get report rows that may have moved beyond a single status in a month.
    ##
    if params['date']
      hash.delete('mi_plan_status_in')
      hash.delete('mi_plan_status_eq')
      hash.delete('mi_attempt_status_eq')
      hash.delete('phenotype_attempt_status_eq')
      hash.delete('phenotype_attempt_status_ci_in')
    end


    hash.delete('type')
    hash.delete('no_limit')

    puts params.inspect
  end

  def translate_date(hash, type, no_lower_limit = false)
    return if hash['date'].blank?
    month_begins = Date.parse(hash['date'])
    next_month = month_begins + 1.month

    month_begins = month_begins.to_s
    next_month = next_month.to_s

    if type == 'Aborted - ES Cell QC Failed'
      if !no_lower_limit
        hash['aborted_es_cell_qc_failed_date_gteq'] = month_begins
      end
      hash['aborted_es_cell_qc_failed_date_lt'] = next_month

    elsif type == 'gene_interest_date'
      if !no_lower_limit
        hash['gene_interest_date_gteq'] = month_begins
      end
      hash['gene_interest_date_lt'] = next_month

    elsif type == 'Assigned - ES Cell QC In Progress'
      if !no_lower_limit
        hash['assigned_es_cell_qc_in_progress_date_gteq'] = month_begins
      end
      hash['assigned_es_cell_qc_in_progress_date_lt'] = next_month

    elsif type == 'Assigned - ES Cell QC Complete'
      if !no_lower_limit
        hash['assigned_es_cell_qc_complete_date_gteq'] = month_begins
      end
      hash['assigned_es_cell_qc_complete_date_lt'] = next_month

    elsif type == 'Micro-injection in progress'
      if !no_lower_limit
        hash['micro_injection_in_progress_date_gteq'] = month_begins
      end
      hash['micro_injection_in_progress_date_lt'] = next_month

    elsif type == 'Chimeras obtained'
      if !no_lower_limit
        hash['chimeras_obtained_date_gteq'] = month_begins
      end
      hash['chimeras_obtained_date_lt'] = next_month

    elsif type == 'Founders obtained'
      if !no_lower_limit
        hash['founder_obtained_date_gteq'] = month_begins
      end
      hash['founder_obtained_date_lt'] = next_month

    elsif type == 'Genotype confirmed'
      if !no_lower_limit
        hash['genotype_confirmed_date_gteq'] = month_begins
      end
      hash['genotype_confirmed_date_lt'] = next_month

    elsif type == 'Micro-injection aborted'
      if !no_lower_limit
        hash['micro_injection_aborted_date_gteq'] = month_begins
      end
      hash['micro_injection_aborted_date_lt'] = next_month

    elsif type == 'Phenotype Attempt Registered'
      if !no_lower_limit
        hash['phenotyping_registered_date_gteq'] = month_begins
      end
      hash['phenotyping_registered_date_lt'] = next_month

    elsif type == 'Mouse Allele Mod Registered'
      if !no_lower_limit
        hash['mouse_allele_mod_registered_date_gteq'] = month_begins
      end
      hash['mouse_allele_mod_registered_date_lt'] = next_month

    elsif type == 'Rederivation Started'
      if !no_lower_limit
        hash['rederivation_started_date_gteq'] = month_begins
      end
      hash['rederivation_started_date_lt'] = next_month

    elsif type == 'Rederivation Complete'
      if !no_lower_limit
        hash['rederivation_complete_date_gteq'] = month_begins
      end
      hash['rederivation_complete_date_lt'] = next_month

    elsif type == 'Cre Excision Started'
      if !no_lower_limit
        hash['cre_excision_started_date_gteq'] = month_begins
      end
      hash['cre_excision_started_date_lt'] = next_month

    elsif type == 'Cre Excision Complete'
      if !no_lower_limit
        hash['cre_excision_complete_date_gteq'] = month_begins
      end
      hash['cre_excision_complete_date_lt'] = next_month

    elsif type == 'Phenotyping Started'
      if !no_lower_limit
        hash['phenotyping_started_date_gteq'] = month_begins
      end
      hash['phenotyping_started_date_lt'] = next_month

    elsif type == 'Phenotyping Experiments Started'
      if !no_lower_limit
        hash['phenotyping_experiments_started_date_gteq'] = month_begins
      end
      hash['phenotyping_experiments_started_date_lt'] = next_month

    elsif type == 'Phenotyping Complete'
      if !no_lower_limit
        hash['phenotyping_complete_date_gteq'] = month_begins
      end
      hash['phenotyping_complete_date_lt'] = next_month

    elsif type == 'Phenotype Attempt Aborted'
      if !no_lower_limit
        hash['phenotyping_aborted_date_gteq'] = month_begins
      end
      hash['phenotyping_aborted_date_lt'] = next_month
    end


    hash.delete('date')
  end

  def authenticate_user_if_not_sanger
    if ! /sanger/.match request.headers['HTTP_CLIENTREALM'].to_s
      authenticate_user!
    end
  end

  public

  def mmrrc
    centre = params[:centre]
    type = params[:type]

    #puts "#### centre: '#{centre}' - type: '#{type}'"

    mmrrc_reports = MmrrcNew.new.get_files

    filename = mmrrc_reports[centre][type]

    data = File.read(filename)

    response.headers['Content-Length'] = data.size.to_s

    ofilename = "#{centre.gsub(/\s+/, '-')}-#{type.gsub(/\s+/, '-')}-#{Time.now.strftime('%d-%m-%y--%H-%M')}.tsv".downcase

    #puts "#### ofilename: '#{ofilename}'"

    send_data data,
      :type => 'text/tsv; charset=iso-8859-1; header=present',
      :disposition => "attachment; filename=#{ofilename}"
  end

end
