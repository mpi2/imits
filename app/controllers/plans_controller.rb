# encoding: utf-8

class PlansController < ApplicationController
  respond_to :html, :only => [:gene_summary, :index, :show, :update]
  respond_to :json, :except => [:gene_summary, :update, :create, :show]
  before_filter :authenticate_user!

  alias_method :public_plan_url, :plan_url
  protected :public_plan_url
  alias_method :public_plans_url, :plans_url
  protected :public_plans_url

  helper do
    def public_plans_path(*args); plans_path(*args); end
    def public_plan_path(*args); plan_path(*args); end
  end

  def gene_summary
    q = params[:q] ||= {}

    q[:marker_symbol_or_mgi_accession_id_ci_in] ||= ''
    q[:marker_symbol_or_mgi_accession_id_ci_in] =
            q[:marker_symbol_or_mgi_accession_id_ci_in].
            lines.map(&:strip).select{|i|!i.blank?}.join("\n")

    @access = true
  end

  def show
    @plan = Public::Plan.find(params[:id])
    @intentions = @plan.plan_intentions
    @consortium_intentions = PlanIntention.joins(:plan).where("plan_id != #{@plan.id} AND plans.consortium_id = #{@plan.consortium_id} AND plans.gene_id = #{@plan.gene_id}")
    @intentions_causing_conflicts = @intentions.select{|intent| intent.conflict == true && intent.withdrawn == false}.map{|intent| PlanIntention.join(:plan).where("plan_id != #{@plan.id} AND plans.gene_id = #{@plan.gene_id} AND withdrawn = false AND intention_id = #{intent.intention_id}")}.flatten

    respond_with @plan do |format|
      format.json do
        render :json => @plan
      end
    end
  end


  def index
    # need to search for null if grid filter searches for false.
    convert_false_to_null_params = ['es_cell_qc_intent',
                                    'es_cell_mi_attempt_intent',
                                    'nuclease_mi_attempt_intent',
                                    'mouse_allele_modification_intent',
                                    'phenotyping_intent']

    if params.has_key?("q")
      convert_false_to_null_params.each do |p|
        {'neq' => true, 'eq' => false}.each do |cond, value|
          new_p = "#{p}_#{cond}"
          if params["q"].has_key?(new_p) && params["q"][new_p] == value.to_s
            params["q"].delete(new_p)
            params["q"]["#{p}_null"] = true
          end
        end
      end
    end

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

  def create
    # only adds intentions to plans, No removals allowed

    #Do not allow creation of intentions through nested attributes.
    params.delete(:plan_intentions_attributes)

    plan_param = params[:plan]

    consortium_name        = plan_param[:consortium_name]
    production_centre_name = plan_param[:production_centre_name]
    marker_symbol          = plan_param[:marker_symbol]

    if !marker_symbol.blank? && !production_centre_name.blank? && !consortium_name.blank?
      plans = Public::Plan.joins(:gene, :consortium, :production_centre).where("genes.marker_symbol = '#{marker_symbol}' AND centres.name = '#{production_centre_name}' AND consortia.name = '#{consortium_name}'")
    else
      plans = nil
    end
    
    unless plans.blank? 
      plan = Public::Plan.find(plans.first.id)
    else
      plan = Public::Plan.new(plan_param)
    end

    intentions = ['es_cell_qc_intent', 'es_cell_mi_attempt_intent', 'nuclease_mi_attempt_intent', 'mouse_allele_modification_intent', 'phenotyping_intent']

    intentions.each do |intention|
      if plan_param.has_key?(intention) && plan_param[intention] == true && plan.send(intention) != true
        plan.send("#{intention}=", true)

        # Set priority if centre adds intend to use ES Cells
        if ['es_cell_qc_intent', 'es_cell_mi_attempt_intent'].include?(intention) && !plan_param[:priority_name].blank?
          plan.priority_name = plan_param[:priority_name]
        end
      end
    end

    plan.default_sub_project_name = plan_param[:default_sub_project_name] if plan_param.has_key?(:default_sub_project_name)

    if plan.valid?
      plan.save!
      render :json => plan
    else
      render :json => plan.errors, :status => 422
    end


  end

  def update
    # if request comes from grid (i.e. extended_response = true || not blank) then disable nested_attributes else disable intention boolean update 
    if params[:extended_response]
      params[:plan].delete(:plan_intentions_attributes)
    else
      params[:plan].delete(:es_cell_qc_intent)
      params[:plan].delete(:es_cell_mi_attempt_intent)
      params[:plan].delete(:nuclease_mi_attempt_intent)
      params[:plan].delete(:mouse_allele_modification_intent)
      params[:plan].delete(:phenotyping_intent)
    end

    puts "PARAMS #{params[:plan]}"

    @plan = Public::Plan.find_by_id(params[:id])
    @intentions = @plan.plan_intentions
    @consortium_intentions = PlanIntention.joins(:plan).where("plan_id != #{@plan.id} AND plans.consortium_id = #{@plan.consortium_id} AND plans.gene_id = #{@plan.gene_id}")
    @intentions_causing_conflicts = @intentions.select{|intent| intent.conflict == true && intent.withdrawn == false}.map{|intent| PlanIntention.join(:plan).where("plan_id != #{@plan.id} AND plans.gene_id = #{@plan.gene_id} AND withdrawn = false AND intention_id = #{intent.intention_id}")}.flatten

    return unless authorize_user_production_centre(@plan)
    return if empty_payload?(params[:plan])

#    @plan.updated_by = current_user

    if @plan.update_attributes(params[:plan])
      @plan = Public::Plan.find_by_id(@plan.id)
      @intentions = @plan.plan_intentions
      @consortium_intentions = PlanIntention.joins(:plan).where("plan_id != #{@plan.id} AND plans.consortium_id = #{@plan.consortium_id} AND plans.gene_id = #{@plan.gene_id}")
      @intentions_causing_conflicts = @intentions.select{|intent| intent.conflict == true && intent.withdrawn == false}.map{|intent| PlanIntention.join(:plan).where("plan_id != #{@plan.id} AND plans.gene_id = #{@plan.gene_id} AND withdrawn = false AND intention_id = #{intent.intention_id}")}.flatten

      flash.now[:notice] = 'Plan updated successfully'
    end

    respond_with @plan do |format|
      format.html do
        if ! @plan.valid?
          flash.now[:alert] = 'Plan could not be updated - please check the values you entered'
        end
        render :action => :show
      end

      if @plan.valid?
        format.json do
          if params[:extended_response].to_s == 'true'
            render :json => json_format_extended_response(@plan, 1)
          else
            render :json => @plan
          end
        end
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
