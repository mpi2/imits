class V2::ReportsController < ApplicationController

  helper :reports

  def planned_microinjection_summary_and_conflicts
    @impc_consortia_ids = Consortium.where('name not in (?)', ['EUCOMM-EUMODIC','MGP-KOMP','UCD-KOMP']).map(&:id)

    genes_in_priority_groups
  end

  def inspect_micro_injection_plans
    @mi_plans = MiPlan
                  .joins(:consortium, :status)
                  .includes(:priority, :production_centre, :sub_project)
                  .where(:mi_plan_statuses => {:name => ['Inspect - Conflict', 'Inspect - MI Attempt', 'Inspect - GLT Mouse']})
                  .order(:status_id, 'consortia.name')


  end

  def genes_in_priority_groups

    @gene_count = MiPlan.select('count(distinct(gene_id))')
                    .joins(:consortium)
                    .where(:consortium_id => @impc_consortia_ids).first.attributes['count']

    mi_plans = MiPlan.select('consortia.name as consortium_name, mi_plan_priorities.name as priority_name, mi_plan_statuses.name as status_name, count(distinct(gene_id))')
                  .joins(:status, :priority, :consortium)
                  .where(:consortium_id => @impc_consortia_ids, :is_bespoke_allele => false)
                  .order('consortia.name asc')
                  .group('consortium_name, priority_name, status_name')

    @priorities = MiPlan::Priority.all
    @statuses = MiPlan::Status.order('order_by asc')
    @consortia_by_priority = {}
    @consortia_by_status = {}
    @consortia_totals = {}
    @priority_totals = {}
    @status_totals = {}
    @consortia = []

    mi_plans.each do |mi|
      consortium = mi.attributes.to_options[:consortium_name]
      priority     = mi.attributes.to_options[:priority_name]
      status     = mi.attributes.to_options[:status_name]
      count      = mi.attributes.to_options[:count]

      @consortia << consortium

      if @consortia_totals[consortium]
        @consortia_totals[consortium] += count.to_i
      else
        @consortia_totals[consortium] = count.to_i
      end

      if @priority_totals[priority]
        @priority_totals[priority] += count.to_i
      else
        @priority_totals[priority] = count.to_i
      end

      if @status_totals[status]
        @status_totals[status] += count.to_i
      else
        @status_totals[status] = count.to_i
      end

      if @consortia_by_priority["#{consortium} - #{priority}"]
        @consortia_by_priority["#{consortium} - #{priority}"] += count.to_i
      else
        @consortia_by_priority["#{consortium} - #{priority}"] = count.to_i
      end

      if @consortia_by_status["#{consortium} - #{status}"]
        @consortia_by_status["#{consortium} - #{status}"] += count.to_i
      else
        @consortia_by_status["#{consortium} - #{status}"] = count.to_i
      end

      if @consortia_by_priority["#{consortium} - #{priority} - #{status}"]
        @consortia_by_priority["#{consortium} - #{priority} - #{status}"] += count.to_i
      else
        @consortia_by_priority["#{consortium} - #{priority} - #{status}"] = count.to_i
      end
    end

    @consortia.uniq!

    @conflicting_mi_plans = MiPlan
      .joins(:consortium, :priority, :status)
      .includes(:production_centre, :sub_project)
      .where(:mi_plan_statuses => {:name => 'Conflict'})
      .order('consortia.name asc')

    if params[:format] == 'csv'
      inspect_micro_injection_plans
    end

  end


end