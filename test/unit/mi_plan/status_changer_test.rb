# encoding: utf-8

require 'test_helper'

class MiPlan::StatusChangerTest < ActiveSupport::TestCase
  context 'MiPlan::StatusChanger' do

    should 'set status to "Assigned - ES Cells QC In Progress" if number_of_es_cells_starting_qc is set to not null' do
      mi_plan = Factory.create :mi_plan
      assert_equal 'Interest', mi_plan.status

      mi_plan.number_of_es_cells_starting_qc = 0
      mi_plan.valid?

      assert_equal 'Assigned - ES Cell QC In Progress', mi_plan.status
    end

  end
end
