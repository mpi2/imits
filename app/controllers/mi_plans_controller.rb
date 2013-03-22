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

  def search_by_marker_symbol
    @mi_plans_hash = []
    @mi_plans = Gene.find_by_marker_symbol( params[:marker_symbol] ).try(:mi_plans).includes(:consortium, :production_centre, :sub_project, :status, :priority)

    @mi_plans.each do |mi_plan|
        @mi_plans_hash << {
          'id'                             => mi_plan.id,
          'consortium_name'                => mi_plan.consortium.name,
          'production_centre_name'         => mi_plan.production_centre.name,
          'sub_project_name'               => mi_plan.sub_project.name,
          'status_name'                    => mi_plan.status.name,
          'priority_name'                  => mi_plan.priority.name,
          'number_of_es_cells_starting_qc' => mi_plan.number_of_es_cells_starting_qc,
          'number_of_es_cells_passing_qc'  => mi_plan.number_of_es_cells_passing_qc,
          'is_active'                      => mi_plan.is_active,
          'is_bespoke_allele'              => mi_plan.is_bespoke_allele,
          'is_conditional_allele'          => mi_plan.is_conditional_allele,
          'is_deletion_allele'             => mi_plan.is_deletion_allele,
          'is_cre_knock_in_allele'         => mi_plan.is_cre_knock_in_allele,
          'is_cre_bac_allele'              => mi_plan.is_cre_bac_allele,
          'comment'                        => mi_plan.comment,
          'withdrawn'                      => mi_plan.withdrawn,
          'phenotype_only'                 => mi_plan.phenotype_only,
          'created_at'                     => mi_plan.created_at,
          'updated_at'                     => mi_plan.updated_at,
        }
    end
    respond_with @mi_plans_hash.to_json
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
      @mi_plan = Public::MiPlan.create(params[:mi_plan])
      respond_with @mi_plan
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

    if !params[:id].blank?
      @mi_plan = Public::MiPlan.find_by_id(params[:id])
    else
      search_params = {
        :gene_marker_symbol_eq => params[:marker_symbol],
        :consortium_name_eq    => params[:consortium],
      }

      if params[:production_centre].blank?
        search_params[:production_centre_id_null] = true
      else
        search_params[:production_centre_name_eq] = params[:production_centre]
      end

      search_results = Public::MiPlan.search(search_params).result
      @mi_plan = search_results.first if search_results.size == 1
    end

    if !@mi_plan.nil?
      @mi_plan.destroy
      respond_to { |format| format.json { head :ok } }
    else
      respond_to do |format|
        format.json {
          render(
            :json => { :mi_plan => 'Unable to find an mi_plan for the paramaters you have supplied.' },
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
