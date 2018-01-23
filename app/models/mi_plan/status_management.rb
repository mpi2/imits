# encoding: utf-8

module MiPlan::StatusManagement
  extend ActiveSupport::Concern

  class ConflictResolver
    def initialize(gene)
      if gene
        plans = gene.mi_plans
        mi_attempts = gene.mi_attempts
        phenotyping_productions = gene.phenotyping_productions

        @all_gtc_mi_attempts = mi_attempts.search(:status_code_eq => 'gtc').result.all.dup
        @all_non_gtc_active_mi_attempts = mi_attempts.search(:status_code_not_in => ['gtc', 'abt']).result.all.dup
        @all_assigned_plans = plans.where(:status_id => MiPlan::Status.all_assigned.map(&:id)).all
        @all_pre_assignment_plans = plans.where(:status_id => MiPlan::Status.all_pre_assignment.map(&:id)).all
        @all_phenotyping_productions = phenotyping_productions.search(:phenotyping_experiments_started_not_null => 1).result.all.dup
      else
        @all_gtc_mi_attempts = []
        @all_non_gtc_active_mi_attempts = []
        @all_assigned_plans = []
        @all_pre_assignment_plans = []
        @all_phenotyping_productions = []
      end
    end

    def get_pre_assigned_status(plan)
      if plan.es_cell_qc_only == true
        return 'Assigned for ES Cell QC'
      elsif plan.phenotype_only == true
        return 'Inspect - Phenotype Conflict' if @all_phenotyping_productions.size != 0 && plan.force_assignment.blank?
        return 'Assigned to phenotype'
      elsif ! plan.new_record? and ! MiPlan::Status.all_pre_assignment.include?(plan.status)
        return 'Assigned'
      elsif plan.force_assignment == true
        return 'Assigned'
      elsif( @all_gtc_mi_attempts.size != 0 )
        return 'Inspect - GLT Mouse'
      elsif( @all_non_gtc_active_mi_attempts.size != 0 )
        return 'Inspect - MI Attempt'
      elsif( @all_assigned_plans.size != 0 )
        return 'Inspect - Conflict'
      elsif( @all_pre_assignment_plans.size > 1 )
        return 'Conflict'
      end

      return 'Assigned'
    end
  end

  ss = ApplicationModel::StatusManager.new(MiPlan)

  ss.add('Assigned for ES Cell QC') do |plan|
    plan.conflict_resolver.get_pre_assigned_status(plan) == 'Assigned for ES Cell QC'
  end

  ss.add('Assigned to phenotype') do |plan|
    plan.conflict_resolver.get_pre_assigned_status(plan) == 'Assigned to phenotype'
  end

  ss.add('Assigned') do |plan|
    plan.conflict_resolver.get_pre_assigned_status(plan) == 'Assigned'
  end

  ss.add('Inspect - Conflict') do |plan|
    plan.conflict_resolver.get_pre_assigned_status(plan) == 'Inspect - Conflict'
  end

  ss.add('Inspect - MI Attempt') do |plan|
    plan.conflict_resolver.get_pre_assigned_status(plan) == 'Inspect - MI Attempt'
  end

  ss.add('Inspect - GLT Mouse') do |plan|
    plan.conflict_resolver.get_pre_assigned_status(plan) == 'Inspect - GLT Mouse'
  end

  ss.add('Inspect - Phenotype Conflict') do |plan|
    plan.conflict_resolver.get_pre_assigned_status(plan) == 'Inspect - Phenotype Conflict'
  end

  ss.add('Conflict') do |plan|
    plan.conflict_resolver.get_pre_assigned_status(plan) == 'Conflict'
  end

  ss.add('Assigned - ES Cell QC In Progress') do |plan|
    plan.number_of_es_cells_starting_qc != nil and
            plan.number_of_es_cells_starting_qc > 0
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

  included do
    @@status_manager = ss
    cattr_reader :status_manager

    attr_accessor :force_assignment
    attr_accessor :conflict_resolver
    attr_accessor :is_resolving_others
  end

  def change_status
    self.conflict_resolver = ConflictResolver.new(gene)
    self.status = MiPlan::Status.find_by_name!(status_manager.get_status_for(self))
    return true
  end

  def manage_status_stamps
    status_manager.manage_status_stamps_for(self)
  end

  def conflict_resolve_others
    unless is_resolving_others
      plans = gene.mi_plans.search(:status_id_in => MiPlan::Status.all_pre_assignment.map(&:id),
        :id_not_eq => id).result.all
      plans.each {|p| p.is_resolving_others = true; p.save!}
    end
    return true
  end

end
