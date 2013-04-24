class PriorityReportPresenter < GroupReportPresenter

  class << self

    def consortium
      'MGP'
    end

    def intermediate_group_field
      'priority'
    end

    def efficiency_group_field_and_alias
      {
        field: 'mi_plan_priorities.name',
        name:  'priority_name'
      }
    end

    def efficiency_join_statement
      "JOIN mi_plan_priorities ON mi_plan_priorities.id = mi_plans.priority_id"
    end

  end

end