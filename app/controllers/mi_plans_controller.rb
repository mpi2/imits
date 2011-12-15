# encoding: utf-8

class MiPlansController < ApplicationController
  respond_to :html, :only => [:gene_selection]
  respond_to :json, :except => [:gene_selection]
  before_filter :authenticate_user!

  def gene_selection
    q = params[:q] ||= {}

    q[:marker_symbol_or_mgi_accession_id_ci_in] ||= ''
    q[:marker_symbol_or_mgi_accession_id_ci_in] =
            q[:marker_symbol_or_mgi_accession_id_ci_in].
            lines.map(&:strip).select{|i|!i.blank?}.join("\n")

    @centre_combo_options    = Centre.order('name').map(&:name)
    @consortia_combo_options = Consortium.order('name').map(&:name)
    @priority_combo_options  = MiPlan::Priority.order('name').map(&:name)
  end

  def show
    respond_with MiPlan.find_by_id(params[:id])
  end

  def create
    upgradeable = MiPlan.check_for_upgradeable(params[:mi_plan])
    if upgradeable
      message = "#{upgradeable.marker_symbol} has already been selected by #{upgradeable.consortium_name} without a production centre, please add your production centre to that selection"
      render(:json => {'error' => message}, :status => 422)
    else
      @mi_plan = MiPlan.create(params[:mi_plan])
      respond_with @mi_plan
    end
  end

  def update
    @mi_plan = MiPlan.find_by_id(params[:id])
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
      @mi_plan = MiPlan.find_by_id(params[:id])
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

      search_results = MiPlan.search(search_params).result
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
    render :json => data_for_serialized(:json, 'id', MiPlan, :search)
  end

end
