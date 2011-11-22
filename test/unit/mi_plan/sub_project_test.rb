require 'test_helper'

class MiPlan::SubProjectTest < ActiveSupport::TestCase

  context 'MiPlan::SubProject' do

    should have_db_column(:name).with_options(:null => false)

    should 'check has_many mi_plans' do
      sub_project = MiPlan::SubProject.first
      plan = Factory.build :mi_plan
      plan.sub_project_id = sub_project.id
      assert_equal sub_project, plan.sub_project
    end

  end

end
