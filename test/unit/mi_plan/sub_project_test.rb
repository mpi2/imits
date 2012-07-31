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

  context '#has_mi_plans?' do

    should 'check test if sub-project has any mi_plans' do
      sub_project = MiPlan::SubProject.new(:name => 'TESTUNIT')
      sub_project.save!
      before_plan_added = sub_project.has_mi_plan?
      plan = Factory.build :mi_plan
      plan.sub_project_id = sub_project.id
      plan.save!
      after_plan_added = sub_project.has_mi_plan?
      assert_equal before_plan_added, false
      assert_equal after_plan_added, true
    end

  end

end
