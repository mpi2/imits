class SubProjectReportPresenter < GroupReportPresenter

  ## See superclass for inherited methods.

  class << self

    ## The methods marked 'required' must be defined in this subclass, or an error will be raised!

    def consortium # required
      'MGP'
    end

    def intermediate_group_field # required
      'sub_project'
    end

    def efficiency_group_field_and_alias # required
      {
        field: 'mi_plan_sub_projects.name',
        name:  'sub_project_name'
      }
    end

    def efficiency_join_statement # required
      "JOIN mi_plan_sub_projects ON mi_plan_sub_projects.id = mi_plans.sub_project_id"
    end

  end

end