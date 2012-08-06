# encoding: utf-8

module MiPlan::StatusManagement
  extend ActiveSupport::Concern

  class ConflictResolver
    def initialize(gene)
      if gene
        plans = gene.mi_plans
        mi_attempts = gene.mi_attempts

        @all_gtc_mi_attempts = mi_attempts.search(:status_code_eq => 'gtc').result.all.dup
        @all_non_gtc_active_mi_attempts = mi_attempts.search(:status_code_not_in => ['gtc', 'abt']).result.all.dup
        @all_assigned_plans = plans.where(:status_id => MiPlan::Status.all_assigned.map(&:id)).all
        @all_pre_assignment_plans = plans.where(:status_id => MiPlan::Status.all_pre_assignment.map(&:id)).all
      else
        @all_gtc_mi_attempts = []
        @all_non_gtc_active_mi_attempts = []
        @all_assigned_plans = []
        @all_pre_assignment_plans = []
      end
    end

    def get_pre_assigned_status(plan)
      if ! plan.new_record? and ! MiPlan::Status.all_pre_assignment.include?(plan.status)
        return nil
      elsif plan.force_assignment == true
        return nil
      elsif( @all_gtc_mi_attempts.size != 0 )
        return MiPlan::Status['Inspect - GLT Mouse']
      elsif( @all_non_gtc_active_mi_attempts.size != 0 )
        return MiPlan::Status['Inspect - MI Attempt']
      elsif( @all_assigned_plans.size != 0 )
        return MiPlan::Status['Inspect - Conflict']
      elsif( @all_pre_assignment_plans.size > 1 )
        return MiPlan::Status['Conflict']
      end

      return nil
    end
  end

  ss = ApplicationModel::StatusManager.new

  ss.add('Assigned') {true}

  ss.add('Inspect - Conflict') do |plan|
    plan.conflict_resolver.get_pre_assigned_status(plan).try(:name) == 'Inspect - Conflict'
  end

  ss.add('Inspect - MI Attempt') do |plan|
    plan.conflict_resolver.get_pre_assigned_status(plan).try(:name) == 'Inspect - MI Attempt'
  end

  ss.add('Inspect - GLT Mouse') do |plan|
    plan.conflict_resolver.get_pre_assigned_status(plan).try(:name) == 'Inspect - GLT Mouse'
  end

  ss.add('Conflict') do |plan|
    plan.conflict_resolver.get_pre_assigned_status(plan).try(:name) == 'Conflict'
  end

  ss.add('Assigned - ES Cell QC In Progress') do |plan|
    plan.number_of_es_cells_starting_qc != nil
  end

  ss.add('Assigned - ES Cell QC Complete', 'Assigned - ES Cell QC In Progress') do |plan|
    plan.number_of_es_cells_passing_qc != nil and
            plan.number_of_es_cells_passing_qc > 0
  end

  ss.add('Aborted - ES Cell QC Failed') do |plan|
    plan.number_of_es_cells_passing_qc != nil and
            plan.number_of_es_cells_passing_qc == 0
  end

  ss.add('Withdrawn') { |plan| plan.withdrawn? }

  ss.add('Inactive') { |plan| ! plan.is_active? }

  @@status_manager = ss

  def change_status
    self.conflict_resolver = ConflictResolver.new(gene)
    self.status = MiPlan::Status.find_by_name!(@@status_manager.get_status_for(self))
    return true
  end

  def conflict_resolve_others
    unless is_resolving_others
      plans = gene.mi_plans.search(:status_id_in => MiPlan::Status.all_pre_assignment.map(&:id),
        :id_not_eq => id).result.all
      plans.each {|p| p.is_resolving_others = true; p.save!}
    end
    return true
  end

  included do
    attr_accessor :force_assignment
    attr_accessor :conflict_resolver
    attr_accessor :is_resolving_others
  end

end
