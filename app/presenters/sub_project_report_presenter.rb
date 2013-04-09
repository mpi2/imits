class SubProjectReportPresenter < GroupReportPresenter

  class << self

    def consortium
      'MGP'
    end

    def intermediate_group_field
      'sub_project'
    end

    def efficiency_group_field_and_alias
      {
        field: 'mi_plan_sub_projects.name',
        name:  'sub_project_name'
      }
    end

    def efficiency_join_statement
      "JOIN mi_plan_sub_projects ON mi_plan_sub_projects.id = mi_plans.sub_project_id"
    end

  end

end