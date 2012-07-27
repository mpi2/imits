# encoding: utf-8

module MiPlan::StatusChanger
  extend ActiveSupport::Concern

  class ConflictResolver
    def initialize(gene)
      plans = gene.mi_plans
      plans.each {|p| p.conflict_resolver = self}
      partitioned = plans.partition { |p| MiPlan::Status.all_pre_assignment.include? p.status }
      @all_pre_assignment = partitioned[0]
      all_post_assignment = partitioned[1]

      @all_assigned = all_post_assignment.find_all {|p| MiPlan::Status.all_assigned.include?(p.status) }
    end

    def get_status_for(plan)
      # TODO cannot be invoked recursively; set/unset a recursive lock variable
      # around here
      if( @all_assigned.size != 0 )
        return MiPlan::Status['Inspect - Conflict']
      end

      return nil
    end
  end

  ss = ApplicationModel::StatusChangerMachine.new

  ss.add('Assigned') {true}

  # TODO Use conflict_resolver in conditions for each pre-assignment status
  # (e.g. for Conflict status: { conflict_resolver.get_status_for(self) == 'Conflict' } )

  ss.add('Inspect - Conflict') do |plan|
    plan.conflict_resolver.get_status_for(plan).try(:name) == 'Inspect - Conflict'
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

  @@status_changer_machine = ss

  def change_status
    # TODO if conflict_resolver class variable is not set, create it, passing in
    # all plans for this gene that are in a pre-assignment status, including
    # self if it is one
    self.conflict_resolver = ConflictResolver.new(self.gene)
    self.status = MiPlan::Status.find_by_name!(@@status_changer_machine.get_status_for(self))

    # TODO tell conflict_resolver to invoke save on all other conflict
    # resolution status plans in system UNLESS it is already doing it (i.e. when
    # it invokes save on a plan, this step should not be triggered again)
    self.conflict_resolver = nil
  end

  included do
    attr_accessor :force_assignment
    attr_accessor :conflict_resolver
  end
end
