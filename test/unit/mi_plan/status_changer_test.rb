# encoding: utf-8

require 'test_helper'

class MiPlan::StatusChangerTest < ActiveSupport::TestCase
  context 'MiPlan::StatusChanger' do

    should 'set status to "Assigned - ES Cells QC In Progress" if number_of_es_cells_starting_qc is set to not null and passing_qc is null' do
      mi_plan = Factory.create :mi_plan
      assert_equal 'Interest', mi_plan.status.name

      mi_plan.number_of_es_cells_starting_qc = 0
      mi_plan.valid?
      assert_equal 'Assigned - ES Cell QC In Progress', mi_plan.status.name
    end

    should 'set status to "Assigned - ES Cells QC Complete" if number_of_es_cells_passing_qc is set to > 0' do
      mi_plan = Factory.create :mi_plan
      assert_equal 'Interest', mi_plan.status.name

      mi_plan.number_of_es_cells_starting_qc = 10
      mi_plan.number_of_es_cells_passing_qc = nil
      mi_plan.valid?
      assert_equal 'Assigned - ES Cell QC In Progress', mi_plan.status.name

      mi_plan.number_of_es_cells_passing_qc = 6
      mi_plan.valid?
      assert_equal 'Assigned - ES Cell QC Complete', mi_plan.status.name
    end

    should 'set status to "Aborted - ES Cell QC Failed" if number_of_es_cells_passing_qc is set to 0' do
      mi_plan = Factory.create :mi_plan
      assert_equal 'Interest', mi_plan.status.name

      mi_plan.number_of_es_cells_starting_qc = 5
      mi_plan.number_of_es_cells_passing_qc = 0
      mi_plan.valid?
      assert_equal 'Aborted - ES Cell QC Failed', mi_plan.status.name
    end

    should 'not do any status changes if it is currently Inactive' do
      mi_plan = Factory.create :mi_plan, :is_active => false
      assert_equal 'Inactive', mi_plan.status.name

      mi_plan.number_of_es_cells_passing_qc = 6
      mi_plan.valid?
      assert_equal 'Inactive', mi_plan.status.name
    end
    
    should 'set "Inactive" status when is_active is set to false' do
      mi_plan = Factory.create :mi_plan, :is_active => false, :number_of_es_cells_starting_qc => 5
      mi_plan.valid?
      assert_equal 'Inactive', mi_plan.status.name
    end
  end
end
