# encoding: utf-8

class PlansController < ApplicationController
  respond_to :html, :only => [:gene_summary, :index, :show]
  respond_to :json, :except => [:gene_summary]
  before_filter :authenticate_user!

  def gene_summary
    q = params[:q] ||= {}

    q[:marker_symbol_or_mgi_accession_id_ci_in] ||= ''
    q[:marker_symbol_or_mgi_accession_id_ci_in] =
            q[:marker_symbol_or_mgi_accession_id_ci_in].
            lines.map(&:strip).select{|i|!i.blank?}.join("\n")

    @access = true
  end

  def show
    @plan = Plan.find_by_id(params[:id])
    @intentions = @plan.plan_intentions
    @consortium_intentions = PlanIntention.joins(:plan).where("plan_id != #{@plan.id} AND plans.consortium_id = #{@plan.consortium_id} AND plans.gene_id = #{@plan.gene_id}")
    @intentions_causing_conflicts = @intentions.select{|intent| intent.conflict == true && intent.withdrawn == false}.map{|intent| PlanIntention.join(:plan).where("plan_id != #{@plan.id} AND plans.gene_id = #{@plan.gene_id} AND withdrawn = false AND intention_id = #{intent.intention_id}")}.flatten
  end


  def index
    respond_to do |format|
      format.json do
        render :json => data_for_serialized(:json, 'marker_symbol asc', Public::Plan, :public_search, false)
      end

      format.html do
        authenticate_user!
        @access = true
      end
    end
  end

#  def history
#    @resource = Plan.find(params[:id])
#    render :template => '/shared/history'
#  end

  def params_cleaned_for_sort(sorts)
    sorts.gsub!(/production_centre_name/, "centres.name")
    sorts.gsub!(/gene_marker_symbol/, "genes.marker_symbol")
    sorts.gsub!(/consortium_name/, "consortia.name")
    sorts.gsub!(/status_name/, "mi_plan_statuses.name")
    sorts
  end

end
