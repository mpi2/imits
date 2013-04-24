class PriorityReportPresenter < GroupReportPresenter

  ## See superclass for inherited methods.

  class << self

    ## The methods marked 'required' must be defined in this subclass, or an error will be raised!

    def consortium # required
      'MGP'
    end

    def intermediate_group_field # required
      'priority'
    end

    def efficiency_group_field_and_alias # required
      {
        field: 'mi_plan_priorities.name',
        name:  'priority_name'
      }
    end

    def efficiency_join_statement # required
      "JOIN mi_plan_priorities ON mi_plan_priorities.id = mi_plans.priority_id"
    end

  end

end