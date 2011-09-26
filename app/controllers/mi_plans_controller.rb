# encoding: utf-8

class MiPlansController < ApplicationController
  respond_to :html, :only => [:gene_selection]
  respond_to :json, :only => [:create,:destroy]
  before_filter :authenticate_user!

  def gene_selection
    q = params[:q] ||= {}

    q[:marker_symbol_or_mgi_accession_id_ci_in] ||= ''
    q[:marker_symbol_or_mgi_accession_id_ci_in] =
      q[:marker_symbol_or_mgi_accession_id_ci_in]
        .lines
        .map(&:strip)
        .select{|i|!i.blank?}
        .join("\n")

    @centre_combo_options    = Centre.order('name').all.map { |c| { c.id => c.name } }
    @consortia_combo_options = Consortium.order('name').all.map { |c| { c.id => c.name } }
    @priority_combo_options  = MiPlanPriority.all.map { |p| { p.id => p.name } }
    @interest_status_id      = MiPlanStatus.find_by_name!('Interest').id
  end

  def create
    @mi_plan = MiPlan.new(params[:mi_plan])
    respond_to do |format|
      if @mi_plan.save
        format.json { render :json => @mi_plan, :status => :created }
      else
        format.json { render :json => @mi_plan.errors, :status => 400 }
      end
    end
  end

  def destroy
    @mi_plan = nil
    errors = {}

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
      if @mi_plan.mi_plan_status.name == 'Interest'
        @mi_plan.destroy
        respond_to { |format| format.json { head :ok } }
      else
        respond_to do |format|
          format.json {
            render(
              :json => { :mi_plan => 'We only allow the deletion of MiPlans in the "Interest" status.' },
              :status => 403
            )
          }
        end
      end
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

end
