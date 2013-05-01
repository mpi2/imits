class V2::Reports::MiProductionController < ApplicationController

  before_filter :params_cleaned_for_search

  helper :reports

  def production_detail
    @intermediate_report = IntermediateReport.search(params[:q]).result.order('id asc')
  end

  def komp2_production_summary
    @report = Komp2ProductionReportPresenter.new
    @consortium_by_distinct_gene = @report.consortium_by_distinct_gene
    @consortium_by_status        = @report.generate_consortium_by_status
    @consortium_centre_by_status = @report.generate_consortium_centre_by_status
    @consortium_centre_by_cre_phenotyping_status     = @report.generate_consortium_centre_by_phenotyping_status
    @consortium_centre_by_non_cre_phenotyping_status = @report.generate_consortium_centre_by_phenotyping_status(false)
    @gene_efficiency_totals      = @report.generate_gene_efficiency_totals
    @clone_efficiency_totals     = @report.generate_clone_efficiency_totals
    @effort_efficiency_totals     = @report.generate_effort_efficiency_totals
    @mi_plan_statuses = Komp2ProductionReportPresenter.mi_plan_statuses
  end


  def impc_production_detail
    @intermediate_report = IntermediateReport.search(params[:q]).result.order('id asc')
  end

  def impc_production_summary
    @report = ImpcProductionReportPresenter.new
    @consortium_by_distinct_gene = @report.consortium_by_distinct_gene
    @consortium_by_status        = @report.generate_consortium_by_status
    @consortium_centre_by_status = @report.generate_consortium_centre_by_status
    @consortium_centre_by_cre_phenotyping_status     = @report.generate_consortium_centre_by_phenotyping_status
    @consortium_centre_by_non_cre_phenotyping_status = @report.generate_consortium_centre_by_phenotyping_status(false)
    @gene_efficiency_totals      = @report.generate_gene_efficiency_totals
    @clone_efficiency_totals     = @report.generate_clone_efficiency_totals
    @effort_efficiency_totals     = @report.generate_effort_efficiency_totals
    @mi_plan_statuses = ImpcProductionReportPresenter.mi_plan_statuses
  end

  skip_before_filter :authenticate_user!
  before_filter :authenticate_user_if_not_sanger, :only => [:mgp_production_by_subproject, :mgp_production_by_priority]

  def mgp_production_by_subproject
    @report  = SubProjectReportPresenter.new
    @columns = SubProjectReportPresenter.columns

    @status_by_sub_project = @report.report_hash
  end

  def mgp_production_by_priority
    @report  = PriorityReportPresenter.new
    @columns = PriorityReportPresenter.columns

    @status_by_priority = @report.report_hash
  end

  def komp2_summary_by_month
    @report  = Komp2SummaryByMonthPresenter.new
    @clone_columns = Komp2SummaryByMonthPresenter.clone_columns
    @phenotype_columns = Komp2SummaryByMonthPresenter.phenotype_columns
    @consortia = Komp2SummaryByMonthPresenter.available_consortia

    @summary_by_month = @report.report_hash
  end

  def impc_summary_by_month
    @report  = ImpcSummaryByMonthPresenter.new
    @clone_columns = ImpcSummaryByMonthPresenter.clone_columns
    @phenotype_columns = ImpcSummaryByMonthPresenter.phenotype_columns
    @consortia = ImpcSummaryByMonthPresenter.available_consortia

    @summary_by_month = @report.report_hash
  end

  def impc_centre_by_month
    @report = ImpcCentreByMonthPresenter.new
    @centre_by_month = @report.report_rows
    @columns = ImpcCentreByMonthPresenter.columns
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
      if hash['type'].to_s.downcase == 'es cell qc'
        hash['mi_plan_status_in'] = ['Assigned - ES Cell QC Complete', 'Assigned - ES Cell QC In Progress', 'Aborted - ES Cell QC Failed']
        translate_date(hash, hash['mi_plan_status_eq'])

      elsif ['es qc confirmed', 'es cell qc complete'].include?(hash['type'].to_s.downcase)
        hash['mi_plan_status_eq'] = 'Assigned - ES Cell QC Complete'
        translate_date(hash, hash['mi_plan_status_eq'])

      elsif hash['type'].to_s.downcase == 'es cell qc in progress'
        hash['mi_plan_status_eq'] = 'Assigned - ES Cell QC In Progress'
        translate_date(hash, hash['mi_plan_status_eq'])

      elsif ['es cell qc failed', 'es qc failed'].include?(hash['type'].to_s.downcase)
        hash['mi_plan_status_eq'] = 'Aborted - ES Cell QC Failed'
        translate_date(hash, hash['mi_plan_status_eq'])

      elsif hash['type'].to_s.downcase == 'micro-injection in progress'
        hash['mi_attempt_status_eq'] = 'Micro-injection in progress'
        translate_date(hash, hash['mi_attempt_status_eq'])

      elsif hash['type'].to_s.downcase == 'chimeras obtained'
        hash['mi_attempt_status_eq'] = 'Chimeras obtained'
        translate_date(hash, hash['mi_attempt_status_eq'])

      elsif ['genotype confirmed mice', 'genotype confirmed'].include?(hash['type'].to_s.downcase)
        hash['mi_attempt_status_eq'] = 'Genotype confirmed'
        translate_date(hash, hash['mi_attempt_status_eq'])
      
      elsif ['microinjection aborted', 'micro-injection aborted'].include?(hash['type'].to_s.downcase)
        hash['mi_attempt_status_eq'] = 'Micro-injection aborted'
        translate_date(hash, hash['mi_attempt_status_eq'])
      
      elsif ['intent to phenotype', 'phenotype attempt registered'].include?(hash['type'].to_s.downcase)
        hash['phenotype_attempt_status_eq'] = 'Phenotype Attempt Registered'
        translate_date(hash, hash['phenotype_attempt_status_eq'])
      
      elsif hash['type'].to_s.downcase == 'rederivation started'
        hash['phenotype_attempt_status_eq'] = 'Rederivation Started'
        translate_date(hash, hash['phenotype_attempt_status_eq'])
      
      elsif hash['type'].to_s.downcase == 'rederivation completed'
        hash['phenotype_attempt_status_eq'] = 'Rederivation Complete'
        translate_date(hash, hash['phenotype_attempt_status_eq'])
      
      elsif hash['type'].to_s.downcase == 'cre excision started'
        hash['phenotype_attempt_status_eq'] = 'Cre Excision Started'
        translate_date(hash, hash['phenotype_attempt_status_eq'])
      
      elsif hash['type'].to_s.downcase == 'cre excision completed'
        hash['phenotype_attempt_status_eq'] = 'Cre Excision Complete'
        translate_date(hash, hash['phenotype_attempt_status_eq'])
      
      elsif hash['type'].to_s.downcase == 'phenotyping started'
        hash['phenotype_attempt_status_eq'] = 'Phenotyping Started'
        translate_date(hash, hash['phenotype_attempt_status_eq'])
      
      elsif hash['type'].to_s.downcase == 'phenotyping completed'
        hash['phenotype_attempt_status_eq'] = 'Phenotyping Complete'
        translate_date(hash, hash['phenotype_attempt_status_eq'])
      
      elsif ['phenotyping aborted', 'phenotype attempt aborted'].include?(hash['type'].to_s.downcase)
        hash['phenotype_attempt_status_eq'] = 'Phenotype Attempt Aborted'
        translate_date(hash, hash['phenotype_attempt_status_eq'])
      elsif ['genotype confirmed mice 6 months'].include?(hash['type'].to_s.downcase)
        hash['mi_attempt_status_eq'] = 'Genotype confirmed'
        hash['genotype_confirmed_date_gteq'] = 6.months.ago.to_date
      elsif ['microinjection aborted 6 months'].include?(hash['type'].to_s.downcase)
        hash['mi_attempt_status_eq'] = 'Micro-injection aborted'
        hash['micro_injection_aborted_date_gteq'] = 6.months.ago.to_date
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
      end


      hash.delete('type')

      puts params.inspect
    end

    def translate_date(hash, type)
      return if hash['date'].blank?
      
      month_begins = Date.parse(hash['date'])
      next_month = month_begins + 1.month

      if type == 'Aborted - ES Cell QC Failed'
        hash['aborted_es_cell_qc_failed_date_gteq'] = month_begins
        hash['aborted_es_cell_qc_failed_date_lt'] = next_month

      elsif type == 'Assigned - ES Cell QC In Progress'
        hash['assigned_es_cell_qc_in_progress_date_gteq'] = month_begins
        hash['assigned_es_cell_qc_in_progress_date_lt'] = next_month


      elsif type == 'Assigned - ES Cell QC Complete'
        hash['assigned_es_cell_qc_complete_date_gteq'] = month_begins
        hash['assigned_es_cell_qc_complete_date_lt'] = next_month


      elsif type == 'Micro-injection in progress'
        hash['micro_injection_in_progress_date_gteq'] = month_begins
        hash['micro_injection_in_progress_date_lt'] = next_month


      elsif type == 'Chimeras obtained'
        hash['chimeras_obtained_date_gteq'] = month_begins
        hash['chimeras_obtained_date_lt'] = next_month


      elsif type == 'Genotype confirmed'
        hash['genotype_confirmed_date_gteq'] = month_begins
        hash['genotype_confirmed_date_lt'] = next_month


      elsif type == 'Micro-injection aborted'
        hash['micro_injection_aborted_date_gteq'] = month_begins
        hash['micro_injection_aborted_date_lt'] = next_month


      elsif type == 'Phenotype Attempt Registered'
        hash['phenotype_attempt_registered_date_gteq'] = month_begins
        hash['phenotype_attempt_registered_date_lt'] = next_month


      elsif type == 'Rederivation Started'
        hash['rederivation_started_date_gteq'] = month_begins
        hash['rederivation_started_date_lt'] = next_month


      elsif type == 'Rederivation Complete'
        hash['rederivation_complete_date_gteq'] = month_begins
        hash['rederivation_complete_date_lt'] = next_month


      elsif type == 'Cre Excision Started'
        hash['cre_excision_started_date_gteq'] = month_begins
        hash['cre_excision_started_date_lt'] = next_month


      elsif type == 'Cre Excision Complete'
        hash['cre_excision_complete_date_gteq'] = month_begins
        hash['cre_excision_complete_date_lt'] = next_month


      elsif type == 'Phenotyping Started'
        hash['phenotyping_started_date_gteq'] = month_begins
        hash['phenotyping_started_date_lt'] = next_month


      elsif type == 'Phenotyping Complete'
        hash['phenotyping_complete_date_gteq'] = month_begins
        hash['phenotyping_complete_date_lt'] = next_month


      elsif type == 'Phenotype Attempt Aborted'
        hash['phenotype_attempt_aborted_date_gteq'] = month_begins
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