require 'test_helper'

class MiPlan::SubProjectTest < ActiveSupport::TestCase
  
  VERBOSE = true
  
  context 'MiPlan::SubProject' do

    should have_db_column(:name).with_options(:null => false)

    should 'check has_many mi_plans' do

      sub_project = MiPlan::SubProject.first

      puts sub_project.inspect if VERBOSE

      plan = Factory.build :mi_plan

      puts plan.inspect if VERBOSE

      plan.sub_project_id = sub_project.id

      assert_equal sub_project, plan.sub_project

      puts plan.inspect if VERBOSE

    end

  end
  
end
