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
    @consortium_centre_by_phenotyping_status     = @report.generate_consortium_centre_by_phenotyping_status
    @gene_efficiency_totals      = @report.generate_gene_efficiency_totals
    @clone_efficiency_totals     = @report.generate_clone_efficiency_totals
    @mi_plan_statuses = ImpcProductionReportPresenter.mi_plan_statuses
  end

  def mgp_production_by_subproject
    @report  = SubProjectReportPresenter.new
    @columns = SubProjectReportPresenter.columns

    @status_by_sub_project = @report.report_hash
  end

  def mgp_production_by_priority
    @report  = PriorityReportPresenter.new
    @columns = PriorityReportPresenter.columns

    @status_by_sub_project = @report.report_hash
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
        'phenotype_attempt_colony_name' => 'phenotype_attempt_colony_name_eq'
      }
    end

    def translate_param_values(hash)
      if hash['type'] == 'ES Cell QC'
        hash['mi_plan_status_in'] = ['Assigned - ES Cell QC Complete', 'Assigned - ES Cell QC In Progress', 'Aborted - ES Cell QC Failed']
      end

      if hash['type'] == 'ES QC Confirmed'
        hash['mi_plan_status_eq'] = 'Assigned - ES Cell QC Complete'
      end

      if hash['type'] == 'ES QC Failed'
        hash['mi_plan_status_eq'] = 'Aborted - ES Cell QC Failed'
      end

      if hash['type'] == 'Genotype confirmed mice'
        hash['mi_attempt_status_eq'] = 'Genotype confirmed'
      end

      if hash['type'] == 'Microinjection aborted'
        hash['mi_attempt_status_eq'] = 'Micro-injection aborted'
      end

      if hash['type'] == 'Intent to phenotype'
        hash['phenotype_attempt_status_eq'] = 'Phenotype Attempt Registered'
      end

      if hash['type'] == 'Cre excision started'
        hash['phenotype_attempt_status_eq'] = 'Cre Excision Started'
      end

      if hash['type'] == 'Cre excision completed'
        hash['phenotype_attempt_status_eq'] = 'Cre Excision Complete'
      end

      if hash['type'] == 'Phenotyping started'
        hash['phenotype_attempt_status_eq'] = 'Phenotyping Started'
      end

      if hash['type'] == 'Phenotyping completed'
        hash['phenotype_attempt_status_eq'] = 'Phenotyping Complete'
      end

      if hash['type'] == 'Phenotyping aborted'
        hash['phenotype_attempt_status_eq'] = 'Phenotype Attempt Aborted'
      end

      hash.delete('type')
      params.delete('type')
    end

end