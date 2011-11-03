# encoding: utf-8

require 'test_helper'

class MiPlan::StatusChangerTest < ActiveSupport::TestCase
  context 'MiPlan::StatusChanger' do

    should 'set status to "Assigned - ES Cells QC In Progress" if number_of_es_cells_starting_qc is set to not null and passing_qc is null' do
      mi_plan = Factory.create :mi_plan
      assert_equal 'Interest', mi_plan.status

      mi_plan.number_of_es_cells_starting_qc = 0
      mi_plan.valid?
      assert_equal 'Assigned - ES Cell QC In Progress', mi_plan.status
    end

    should 'set status to "Assigned - ES Cells QC Complete" if number_of_es_cells_passing_qc is set to > 0' do
      mi_plan = Factory.create :mi_plan
      assert_equal 'Interest', mi_plan.status

      mi_plan.number_of_es_cells_starting_qc = 0
      mi_plan.number_of_es_cells_passing_qc = 0
      mi_plan.valid?
      assert_equal 'Assigned - ES Cell QC In Progress', mi_plan.status

      mi_plan.number_of_es_cells_passing_qc = nil
      mi_plan.valid?
      assert_equal 'Assigned - ES Cell QC In Progress', mi_plan.status

      mi_plan.number_of_es_cells_passing_qc = 6
      mi_plan.valid?
      assert_equal 'Assigned - ES Cell QC Complete', mi_plan.status
    end

    should 'not do any status changes if it is currently Inactive' do
      mi_plan = Factory.create :mi_plan, :mi_plan_status => MiPlanStatus[:Inactive]
      assert_equal 'Inactive', mi_plan.status

      mi_plan.number_of_es_cells_passing_qc = 6
      mi_plan.valid?
      assert_equal 'Inactive', mi_plan.status
    end

  end
end
