class V2::Reports::MiProductionController < ApplicationController

  before_filter :params_cleaned_for_search, :except => [:all_mi_attempt_summary, :genes_gt_mi_attempt_summary, :planned_microinjection_list]

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

  def production_detail
    @intermediate_report = NewIntermediateReport.search(params[:q]).result.order('id asc')
  end

  def gene_production_detail
    @intermediate_report = NewGeneIntermediateReport.search(params[:q]).result.order('id asc')
    render :template => 'v2/reports/mi_production/production_detail'
  end

  def consortia_production_detail
    @intermediate_report = NewConsortiaIntermediateReport.search(params[:q]).result.order('id asc')
    render :template => 'v2/reports/mi_production/production_detail'
  end

  def komp2_production_summary
    @title = Komp2ProductionReport.title

    @report = Komp2ProductionReport.new
    @consortium_by_distinct_gene = @report.consortium_by_distinct_gene
    @consortium_by_status        = @report.generate_consortium_by_status
    @consortium_centre_by_status = @report.generate_consortium_centre_by_status
    @consortium_centre_by_cre_phenotyping_status     = @report.generate_consortium_centre_by_phenotyping_status(cre_excision_required = true)
    @consortium_centre_by_non_cre_phenotyping_status = @report.generate_consortium_centre_by_phenotyping_status(cre_excision_required = false)
    @distribution_centre_counts = @report.generate_distribution_centre_counts
    @phenotyping_data_flow_started_counts = @report.generate_phenotyping_data_flow_started_counts
    @gene_efficiency_totals      = @report.generate_gene_efficiency_totals
    @clone_efficiency_totals     = @report.generate_clone_efficiency_totals
    @effort_efficiency_totals     = @report.generate_effort_efficiency_totals
    @mi_plan_statuses = Komp2ProductionReport.mi_plan_statuses


    render :template => 'v2/reports/mi_production/production_summary'
  end

  def impc_production_summary
    @title = ImpcProductionReport.title
    @report = ImpcProductionReport.new
    @consortium_by_distinct_gene = @report.consortium_by_distinct_gene
    @consortium_by_status        = @report.generate_consortium_by_status
    @consortium_centre_by_status = @report.generate_consortium_centre_by_status
    @consortium_centre_by_cre_phenotyping_status     = @report.generate_consortium_centre_by_phenotyping_status(cre_excision_required = true)
    @consortium_centre_by_non_cre_phenotyping_status = @report.generate_consortium_centre_by_phenotyping_status(cre_excision_required = false)
    @distribution_centre_counts = @report.generate_distribution_centre_counts
    @phenotyping_data_flow_started_counts = @report.generate_phenotyping_data_flow_started_counts
    @gene_efficiency_totals      = @report.generate_gene_efficiency_totals
    @clone_efficiency_totals     = @report.generate_clone_efficiency_totals
    @effort_efficiency_totals     = @report.generate_effort_efficiency_totals
    @mi_plan_statuses = ImpcProductionReport.mi_plan_statuses


    render :template => 'v2/reports/mi_production/production_summary'
  end

  def eucomm_tools_production_summary
    @title = EucommToolsProductionReport.title
    @report = EucommToolsProductionReport.new
    @consortium_by_distinct_gene = @report.consortium_by_distinct_gene
    @consortium_by_status        = @report.generate_consortium_by_status
    @consortium_centre_by_status = @report.generate_consortium_centre_by_status
    @consortium_centre_by_cre_phenotyping_status     = @report.generate_consortium_centre_by_phenotyping_status(cre_excision_required = true)
    @consortium_centre_by_non_cre_phenotyping_status = @report.generate_consortium_centre_by_phenotyping_status(cre_excision_required = false)
    @distribution_centre_counts = @report.generate_distribution_centre_counts
    @phenotyping_data_flow_started_counts = @report.generate_phenotyping_data_flow_started_counts
    @gene_efficiency_totals      = @report.generate_gene_efficiency_totals
    @clone_efficiency_totals     = @report.generate_clone_efficiency_totals
    @effort_efficiency_totals     = @report.generate_effort_efficiency_totals
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
    @report  = Komp2SummaryByMonthReport.new
    @clone_columns = Komp2SummaryByMonthReport.clone_columns
    @phenotype_columns = Komp2SummaryByMonthReport.phenotype_columns
    @consortia = Komp2SummaryByMonthReport.available_consortia

    @summary_by_month = @report.report_hash
  end

  def impc_summary_by_month
    @report  = ImpcSummaryByMonthReport.new
    @clone_columns = ImpcSummaryByMonthReport.clone_columns
    @phenotype_columns = ImpcSummaryByMonthReport.phenotype_columns
    @consortia = ImpcSummaryByMonthReport.available_consortia

    @summary_by_month = @report.report_hash
  end

   def komp2_graph_report_display
    @report = Komp2GraphReportDisplay.new
    date = Komp2GraphReportDisplay.date_previous_month.to_date.at_beginning_of_month
    @consortia = Komp2GraphReportDisplay.available_consortia
    @date = date.to_s
    @date_name = Date::ABBR_MONTHNAMES[date.month]
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
    @report = ImpcCentreByMonthReport.new
    @centre_by_month = @report.report_rows
    @cumulative_totals = @report.cumulative_totals
    @consortia = @report.consortia
    @columns = ImpcCentreByMonthReport.columns
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

  def impc_centre_pa_detail
    @report = ImpcCentreByMonthDetail.new
    @centre = params[:centre]
    @pas = @report.pa_rows(@centre)
  end

  def genes_gt_mi_attempt_summary
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
    @report = SlidingEfficiencyReport.new(@consortium_name, @production_centre_name)
    bpr = BaseProductionReport.new
    bpr.class.available_consortia = [@consortium_name]
    @effort_efficiency_totals = bpr.effort_efficiency_totals
  end

  private
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
        'consortium'                    => 'consortium_eq',
        'sub_project'                   => 'sub_project_eq',
        'priority'                      => 'priority_eq',
        'pcentre'                       => 'production_centre_eq',
        'production_centre'             => 'production_centre_eq',
        'gene'                          => 'gene_eq',
        'mgi_accession_id'              => 'mgi_accession_id_eq',
        'ikmc_project_id'               => 'ikmc_project_id_eq',
        'status'                        => 'mi_plan_status_eq',
        'overall_status'                => 'overall_status_eq',
        'mi_plan_status'                => 'mi_plan_status_eq',
        'mi_attempt_status'             => 'mi_attempt_status_eq',
        'phenotype_attempt_status'      => 'phenotype_attempt_status_eq',
        'ikmc_project_id'               => 'ikmc_project_id_eq',
        'mutation_sub_type'             => 'mutation_sub_type_eq',
        'allele_symbol'                 => 'allele_symbol_eq',
        'genetic_background'            => 'genetic_background_eq',
        'mi_attempt_colony_name'        => 'mi_attempt_colony_name_eq',
        'mi_attempt_consortium'         => 'mi_attempt_consortium_eq',
        'mi_attempt_production_centre'  => 'mi_attempt_production_centre_eq',
        'phenotype_attempt_colony_name' => 'phenotype_attempt_colony_name_eq',
        'cre_excision_required'         => 'phenotype_attempt_cre_excision_required_eq'
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
        hash['mi_attempt_status_ci_in'] = ['Micro-injection in progress', 'Chimeras obtained', 'Genotype confirmed', 'Micro-injection aborted']
        translate_date(hash, 'Micro-injection in progress', lower_limit)

      elsif ['micro-injection in progress', 'cumulative mis'].include?(hash['type'].to_s.downcase)
        hash['mi_attempt_status_eq'] = 'Micro-injection in progress'
        translate_date(hash, hash['mi_attempt_status_eq'], lower_limit)

      elsif ['chimaeras produced', 'chimeras obtained', 'chimeras'].include?(hash['type'].to_s.downcase)
        hash['mi_attempt_status_eq'] = 'Chimeras obtained'
        translate_date(hash, hash['mi_attempt_status_eq'], lower_limit)

      elsif ['genotype confirmed mice', 'genotype confirmed', 'cumulative genotype confirmed'].include?(hash['type'].to_s.downcase)
        hash['mi_attempt_status_eq'] = 'Genotype confirmed'
        translate_date(hash, hash['mi_attempt_status_eq'], lower_limit)

      elsif ['microinjection aborted', 'micro-injection aborted'].include?(hash['type'].to_s.downcase)
        hash['mi_attempt_status_eq'] = 'Micro-injection aborted'
        translate_date(hash, hash['mi_attempt_status_eq'], lower_limit)

      elsif ['phenotype attempt registered', 'cumulative phenotype registered'].include?(hash['type'].to_s.downcase)
        hash['phenotype_attempt_status_eq'] = 'Phenotype Attempt Registered'
        translate_date(hash, hash['phenotype_attempt_status_eq'], lower_limit)

      elsif ['intent to phenotype', 'registered for phenotyping'].include?(hash['type'].to_s.downcase)
        hash['phenotype_attempt_status_ci_in'] = ['Phenotype Attempt Registered', 'Rederivation Started', 'Rederivation Complete', 'Cre Excision Started', 'Cre Excision Complete', 'Phenotyping Started', 'Phenotyping Complete', 'Phenotype Attempt Aborted']
        translate_date(hash, 'Phenotype Attempt Registered', lower_limit)

      elsif hash['type'].to_s.downcase == 'rederivation started'
        hash['phenotype_attempt_status_eq'] = 'Rederivation Started'
        translate_date(hash, hash['phenotype_attempt_status_eq'], lower_limit)

      elsif hash['type'].to_s.downcase == 'rederivation completed'
        hash['phenotype_attempt_status_eq'] = 'Rederivation Complete'
        translate_date(hash, hash['phenotype_attempt_status_eq'], lower_limit)

      elsif hash['type'].to_s.downcase == 'cre excision started'
        hash['phenotype_attempt_status_eq'] = 'Cre Excision Started'
        translate_date(hash, hash['phenotype_attempt_status_eq'], lower_limit)

      elsif ['cre excision completed', 'cre excision complete', 'cumulative cre excision complete'].include?(hash['type'].to_s.downcase)
        hash['phenotype_attempt_status_eq'] = 'Cre Excision Complete'
        translate_date(hash, hash['phenotype_attempt_status_eq'], lower_limit)

      elsif hash['type'].to_s.downcase == 'phenotyping started'
        hash['phenotype_attempt_status_eq'] = 'Phenotyping Started'
        translate_date(hash, hash['phenotype_attempt_status_eq'], lower_limit)

      elsif ['phenotyping data flow started', 'cumulative phenotyping data flow started'].include?(hash['type'].to_s.downcase)
        translate_date(hash, 'Phenotyping Data Flow Started', lower_limit)

      elsif ['phenotyping completed', 'phenotyping complete', 'cumulative phenotype complete'].include?(hash['type'].to_s.downcase)
        hash['phenotype_attempt_status_eq'] = 'Phenotyping Complete'
        translate_date(hash, hash['phenotype_attempt_status_eq'], lower_limit)

      elsif ['phenotyping aborted', 'phenotype attempt aborted'].include?(hash['type'].to_s.downcase)
        hash['phenotype_attempt_status_eq'] = 'Phenotype Attempt Aborted'
        translate_date(hash, hash['phenotype_attempt_status_eq'], lower_limit)

      elsif ['genotype confirmed mice 6 months'].include?(hash['type'].to_s.downcase)
        hash['mi_attempt_status_eq'] = 'Genotype confirmed'
        hash['genotype_confirmed_date_gteq'] = 6.months.ago.to_date

      elsif ['microinjection aborted 6 months'].include?(hash['type'].to_s.downcase)
        hash['mi_attempt_status_eq'] = 'Micro-injection aborted'
        hash['micro_injection_aborted_date_gteq'] = 6.months.ago.to_date

      elsif ['cre ex phenotype attempt registered', 'cumulative non cre ex phenotype registered'].include?(hash['type'].to_s.downcase)
        hash['cre_ex_phenotype_attempt_status_eq'] = 'Phenotype Attempt Registered'
        translate_date(hash, hash['phenotype_attempt_status_eq'], lower_limit)

      elsif ['cre ex intent to phenotype'].include?(hash['type'].to_s.downcase)
        hash['cre_ex_phenotype_attempt_status_ci_in'] = ['Phenotype Attempt Registered', 'Rederivation Started', 'Rederivation Complete', 'Cre Excision Started', 'Cre Excision Complete', 'Phenotyping Started', 'Phenotyping Complete', 'Phenotype Attempt Aborted']
        translate_date(hash, 'Phenotype Attempt Registered', lower_limit)

      elsif hash['type'].to_s.downcase == 'cre ex rederivation started'
        hash['cre_ex_phenotype_attempt_status_eq'] = 'Rederivation Started'
        translate_date(hash, hash['phenotype_attempt_status_eq'], lower_limit)

      elsif hash['type'].to_s.downcase == 'cre ex rederivation completed'
        hash['cre_ex_phenotype_attempt_status_eq'] = 'Rederivation Complete'
        translate_date(hash, hash['phenotype_attempt_status_eq'], lower_limit)

      elsif hash['type'].to_s.downcase == 'cre ex cre excision started'
        hash['cre_ex_phenotype_attempt_status_eq'] = 'Cre Excision Started'
        translate_date(hash, hash['phenotype_attempt_status_eq'], lower_limit)

      elsif ['cre ex cre excision completed', 'cre ex cre excision complete', 'cumulative cre ex cre excision complete'].include?(hash['type'].to_s.downcase)
        hash['cre_ex_phenotype_attempt_status_eq'] = 'Cre Excision Complete'
        translate_date(hash, hash['phenotype_attempt_status_eq'], lower_limit)

      elsif hash['type'].to_s.downcase == 'cre ex phenotyping started'
        hash['cre_ex_phenotype_attempt_status_eq'] = 'Phenotyping Started'
        translate_date(hash, hash['phenotype_attempt_status_eq'], lower_limit)

      elsif ['cre ex phenotyping completed', 'cre ex phenotyping complete', 'cumulative cre ex phenotype complete'].include?(hash['type'].to_s.downcase)
        hash['cre_ex_phenotype_attempt_status_eq'] = 'Phenotyping Complete'
        translate_date(hash, hash['phenotype_attempt_status_eq'], lower_limit)

      elsif ['cre ex phenotyping aborted', 'cre ex phenotype attempt aborted'].include?(hash['type'].to_s.downcase)
        hash['cre_ex_phenotype_attempt_status_eq'] = 'Phenotype Attempt Aborted'
        translate_date(hash, hash['phenotype_attempt_status_eq'], lower_limit)

      elsif ['non cre ex phenotype attempt registered', 'cumulative non cre ex phenotype registered'].include?(hash['type'].to_s.downcase)
        hash['non_cre_ex_phenotype_attempt_status_eq'] = 'Phenotype Attempt Registered'
        translate_date(hash, hash['phenotype_attempt_status_eq'], lower_limit)

      elsif ['non cre ex intent to phenotype'].include?(hash['type'].to_s.downcase)
        hash['non_cre_ex_phenotype_attempt_status_ci_in'] = ['Phenotype Attempt Registered', 'Rederivation Started', 'Rederivation Complete', 'Cre Excision Started', 'Cre Excision Complete', 'Phenotyping Started', 'Phenotyping Complete', 'Phenotype Attempt Aborted']
        translate_date(hash, 'Phenotype Attempt Registered', lower_limit)

      elsif hash['type'].to_s.downcase == 'non cre ex rederivation started'
        hash['non_cre_ex_phenotype_attempt_status_eq'] = 'Rederivation Started'
        translate_date(hash, hash['phenotype_attempt_status_eq'], lower_limit)

      elsif hash['type'].to_s.downcase == 'non cre ex rederivation completed'
        hash['non_cre_ex_phenotype_attempt_status_eq'] = 'Rederivation Complete'
        translate_date(hash, hash['phenotype_attempt_status_eq'], lower_limit)

      elsif hash['type'].to_s.downcase == 'non cre ex cre excision started'
        hash['non_cre_ex_phenotype_attempt_status_eq'] = 'Cre Excision Started'
        translate_date(hash, hash['phenotype_attempt_status_eq'], lower_limit)

      elsif ['non cre ex cre excision completed', 'non cre ex cre excision complete', 'cumulative non cre ex cre excision complete'].include?(hash['type'].to_s.downcase)
        hash['non_cre_ex_phenotype_attempt_status_eq'] = 'Cre Excision Complete'
        translate_date(hash, hash['phenotype_attempt_status_eq'], lower_limit)

      elsif hash['type'].to_s.downcase == 'non cre ex phenotyping started'
        hash['non_cre_ex_phenotype_attempt_status_eq'] = 'Phenotyping Started'
        translate_date(hash, hash['phenotype_attempt_status_eq'], lower_limit)

      elsif ['non cre ex phenotyping completed', 'non cre ex phenotyping complete', 'cumulative non cre ex phenotype complete'].include?(hash['type'].to_s.downcase)
        hash['non_cre_ex_phenotype_attempt_status_eq'] = 'Phenotyping Complete'
        translate_date(hash, hash['phenotype_attempt_status_eq'], lower_limit)

      elsif ['non cre ex phenotyping aborted', 'non cre ex phenotype attempt aborted'].include?(hash['type'].to_s.downcase)
        hash['non_cre_ex_phenotype_attempt_status_eq'] = 'Phenotype Attempt Aborted'
        translate_date(hash, hash['phenotype_attempt_status_eq'], lower_limit)

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
          hash['phenotype_attempt_registered_date_gteq'] = month_begins
        end
        hash['phenotype_attempt_registered_date_lt'] = next_month

      elsif type == 'Cre Ex Phenotype Attempt Registered'
        if !no_lower_limit
          hash['cre_ex_phenotype_attempt_registered_date_gteq'] = month_begins
        end
        hash['cre_ex_phenotype_attempt_registered_date_lt'] = next_month

      elsif type == 'Non Cre Ex Phenotype Attempt Registered'
        if !no_lower_limit
          hash['non_cre_ex_phenotype_attempt_registered_date_gteq'] = month_begins
        end
        hash['non_cre_ex_phenotype_attempt_registered_date_lt'] = next_month

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

      elsif type == 'Phenotyping Data Flow Started'
        if !no_lower_limit
          hash['phenotyping_data_flow_started_date_gteq'] = month_begins
        end
        hash['phenotyping_data_flow_started_date_lt'] = next_month

      elsif type == 'Phenotyping Complete'
        if !no_lower_limit
          hash['phenotyping_complete_date_gteq'] = month_begins
        end
        hash['phenotyping_complete_date_lt'] = next_month

      elsif type == 'Phenotype Attempt Aborted'
        if !no_lower_limit
          hash['phenotype_attempt_aborted_date_gteq'] = month_begins
        end
        hash['phenotype_attempt_aborted_date_lt'] = next_month
      end


      hash.delete('date')
    end

    def authenticate_user_if_not_sanger
      if ! /sanger/.match request.headers['HTTP_CLIENTREALM'].to_s
        authenticate_user!
      end
    end

end