# encoding: utf-8

class MiPlansController < ApplicationController
  respond_to :html, :only => [:gene_selection, :index, :show, :destroy]
  respond_to :json, :except => [:gene_selection]
  before_filter :authenticate_user!

  def gene_selection
    q = params[:q] ||= {}

    q[:marker_symbol_or_mgi_accession_id_ci_in] ||= ''
    q[:marker_symbol_or_mgi_accession_id_ci_in] =
            q[:marker_symbol_or_mgi_accession_id_ci_in].
            lines.map(&:strip).select{|i|!i.blank?}.join("\n")

    @access = true
  end

  def show
    set_centres_and_consortia
    @mi_plan = Public::MiPlan.find_by_id(params[:id])
    respond_with @mi_plan
  end

  def search_for_available_phenotyping_plans
    #must pass params hash with :marker_symbol and a :mi_plan_id associated with an mi_attempt
    sql = <<-SQL
      SELECT mi_plans.* FROM mi_plans JOIN genes ON mi_plans.gene_id = genes.id
      WHERE  (mi_plans.is_active AND (NOT mi_plans.withdrawn) AND genes.marker_symbol = '#{params[:marker_symbol]}')
         AND (mi_plans.phenotype_only OR mi_plans.id = '#{params[:mi_plan_id]}')
    SQL

    @mi_plans = MiPlan.find_by_sql(sql)
    params[:id_in] = []
    @mi_plans.each do |mi_plan|
      params[:id_in] << mi_plan.id
    end
    params.delete(:marker_symbol)
    params[:id_in]
    respond_to do |format|
      format.json do
        render :json => data_for_serialized(:json, 'consortium_name asc', Public::MiPlan, :public_search, false)
      end
    end
  end

  def search_for_available_mi_attempt_plans()
    marker_symbol = ''
    crispr = false
    if params.has_key?(:crispr) and params[:crispr] == 'true'
      crispr = true
    end

    if params.has_key?(:marker_symbol)
      marker_symbol = params[:marker_symbol]
      if Gene.find_by_marker_symbol(marker_symbol).blank?
        marker_symbol = Gene.find(:first, :conditions => ["lower(marker_symbol) = ?", marker_symbol.downcase]).try(:marker_symbol)
      end
    end

    sql = <<-SQL
      SELECT mi_plans.* FROM mi_plans JOIN genes ON mi_plans.gene_id = genes.id
      WHERE genes.marker_symbol = '#{marker_symbol}' AND mi_plans.is_active AND (NOT mi_plans.withdrawn) AND (NOT phenotype_only)
            AND (mi_plans.mutagenesis_via_crispr_cas9 = #{crispr})
    SQL

    if crispr
      sql << 'AND (mi_plans.mutagenesis_via_crispr_cas9 IS NULL or mi_plans.mutagenesis_via_crispr_cas9 = true)'
    end

    @mi_plans = MiPlan.find_by_sql(sql)
    params[:id_in] = []
    @mi_plans.each do |mi_plan|
      params[:id_in] << mi_plan.id
    end
    params.delete(:marker_symbol)
    params[:id_in]
    respond_to do |format|
      format.json do
        render :json => data_for_serialized(:json, 'consortium_name asc', Public::MiPlan, :public_search, false)
      end
    end
  end

  alias_method :public_mi_plan_url, :mi_plan_url
  protected :public_mi_plan_url
  alias_method :public_mi_plans_url, :mi_plans_url
  protected :public_mi_plans_url
  helper do
    def public_mi_plans_path(*args); mi_plans_path(*args); end
    def public_mi_plan_path(*args); mi_plan_path(*args); end
  end

  def create
    render :json => {
      'error' => 'Plans cannot be created or modified in iMits anymore. Please visit the new tracking system webpage www.gentar.org/tracker/'
    }, :status => 401
    return true
  end

  def update
    render :json => {
      'error' => 'Plans cannot be created or modified in iMits anymore. Please visit the new tracking system webpage www.gentar.org/tracker/'
    }, :status => 401
    return true
  end

  def destroy
    render :json => {
      'error' => 'Plans cannot be deleted in iMits anymore. Please visit the new tracking system webpage www.gentar.org/tracker/'
    }, :status => 401
    return true
  end

  def index
    respond_to do |format|
      format.json do
        render :json => data_for_serialized(:json, 'marker_symbol asc', Public::MiPlan, :public_search, false)
      end

      format.html do
        authenticate_user!
        @access = true
      end
    end
  end

  def history
    @resource = MiPlan.find(params[:id])
    render :template => '/shared/history'
  end

  def attributes
    render :json => create_attribute_documentation_for(Public::MiPlan)
  end

  def params_cleaned_for_sort(sorts)
    sorts.gsub!(/production_centre_name/, "centres.name")
    sorts.gsub!(/gene_marker_symbol/, "genes.marker_symbol")
    sorts.gsub!(/consortium_name/, "consortia.name")
    sorts.gsub!(/status_name/, "mi_plan_statuses.name")
    sorts.gsub!(/priority_name/, "mi_plan_priorities.name")
    sorts.gsub!(/sub_project_name/, "mi_plan_sub_projects.name")

    sorts
  end

end
