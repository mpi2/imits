# encoding: utf-8

class MiPlansController < ApplicationController
  respond_to :html, :only => [:gene_selection, :index, :show]
  respond_to :json, :except => [:gene_selection]
  before_filter :authenticate_user!

  def gene_selection
    q = params[:q] ||= {}

    q[:marker_symbol_or_mgi_accession_id_ci_in] ||= ''
    q[:marker_symbol_or_mgi_accession_id_ci_in] =
            q[:marker_symbol_or_mgi_accession_id_ci_in].
            lines.map(&:strip).select{|i|!i.blank?}.join("\n")
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
        render :json => data_for_serialized(:json, 'consortium_name asc', Public::MiPlan, :public_search)
      end
    end
  end

  def search_for_available_mi_attempt_plans
    sql = <<-SQL
      SELECT mi_plans.* FROM mi_plans JOIN genes ON mi_plans.gene_id = genes.id
      WHERE genes.marker_symbol = '#{params[:marker_symbol]}' AND mi_plans.is_active AND (NOT mi_plans.withdrawn) AND (NOT phenotype_only)
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
        render :json => data_for_serialized(:json, 'consortium_name asc', Public::MiPlan, :public_search)
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
    upgradeable = Public::MiPlan.check_for_upgradeable(params[:mi_plan])
    if upgradeable
      message = "#{upgradeable.marker_symbol} has already been selected by #{upgradeable.consortium_name} without a production centre, please add your production centre to that selection"
      render(:json => {'error' => message}, :status => 422)
    else
      @mi_plan = Public::MiPlan.new(params[:mi_plan])
      if @mi_plan.valid?
        @mi_plan.save!
        respond_with @mi_plan
      else
        render :json => @mi_plan.errors, :status => 422
      end
    end
  end

  def update
    @mi_plan = Public::MiPlan.find_by_id(params[:id])
    if ! @mi_plan
      render(:json => 'mi_plan not found', :status => 422)
    else
      if @mi_plan.update_attributes params[:mi_plan]
        render :json => @mi_plan
      else
        render :json => @mi_plan.errors, :status => 422
      end
    end
  end

  def destroy
    @mi_plan = nil
    error_str = ''

    if !params[:id].blank?
      @mi_plan = Public::MiPlan.where("id = '#{params[:id]}'")
    else
      [:consortium, :marker_symbol, :sub_project, :is_bespoke_allele, :is_conditional_allele, :is_deletion_allele, :is_cre_knock_in_allele, :is_cre_bac_allele].each do |param|
        if !params.has_key?(param)
          error_str = "missing parameter; #{param} is required."
          break
        end
      end

      consortium = Consortium.find_by_name(params[:consortium])
      gene = Gene.find_by_marker_symbol(params[:marker_symbol])
      [consortium, gene].each do |param|
        if param.blank?
          error_str = "Unable to delete mi_plans; consortium or marker symbol has an invalid value."
        end
      end
      if error_str.blank?
        search_params = "gene_id = '#{gene.id}' AND "         \
                        "consortium_id = '#{consortium.id}' AND "         \
                        "sub_project_id = #{MiPlan::SubProject.find_by_name(params[:sub_project]).try(:id)} AND " \
                        "is_bespoke_allele =  #{params[:is_bespoke_allele]} AND "                                 \
                        "is_conditional_allele = #{params[:is_conditional_allele]} AND "                          \
                        "is_deletion_allele = #{params[:is_deletion_allele]} AND "                                \
                        "is_cre_knock_in_allele = #{params[:is_cre_knock_in_allele]} AND "                        \
                        "is_cre_bac_allele = #{params[:is_cre_bac_allele]} "

        production_centre = Centre.find_by_name(params[:production_centre])
        if production_centre.blank?
          search_params += "AND production_centre_id IS NULL "
        else
          search_params += "AND production_centre_id = '#{production_centre.id}'"
        end
        @mi_plan = Public::MiPlan.where(search_params)
        if @mi_plan.count > 1
          error_str = 'Unable to delete mi_plans. Found multiple mi_plans for the paramaters you supplied.'
        elsif @mi_plan.count == 0
          error_str = 'Unable to find an mi_plan for the paramaters you have supplied.'
        end
      end
    end
    if (!@mi_plan.blank?) and @mi_plan.count == 1
      @mi_plan.first.destroy
      respond_to { |format| format.json { head :ok } }
    else
      respond_to do |format|
        format.json {
          render(
            :json => { :mi_plan => error_str },
            :status => 422
          )
        }
      end
    end
  end

  def index
    respond_to do |format|
      format.json do
        render :json => data_for_serialized(:json, 'marker_symbol asc', Public::MiPlan, :public_search)
      end

      format.html do
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
