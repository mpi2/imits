# encoding: utf-8

require 'test_helper'

class MiPlan::StatusChangerTest < ActiveSupport::TestCase
  context 'MiPlan::StatusChanger' do

    def default_mi_plan
      @default_mi_plan ||= Factory.create :mi_plan
    end

    should 'set status to Assigned by default' do
      assert_equal 'Assigned', default_mi_plan.status.name
    end

    should 'set status to "Assigned - ES Cells QC In Progress" if number_of_es_cells_starting_qc is set to not null and passing_qc is null' do
      assert_equal 'Assigned', default_mi_plan.status.name

      default_mi_plan.number_of_es_cells_starting_qc = 0
      default_mi_plan.valid?
      assert_equal 'Assigned - ES Cell QC In Progress', default_mi_plan.status.name
    end

    should 'set status to "Assigned - ES Cells QC Complete" if number_of_es_cells_passing_qc is set to > 0' do
      assert_equal 'Assigned', default_mi_plan.status.name

      default_mi_plan.number_of_es_cells_starting_qc = 10
      default_mi_plan.number_of_es_cells_passing_qc = nil
      default_mi_plan.valid?
      assert_equal 'Assigned - ES Cell QC In Progress', default_mi_plan.status.name

      default_mi_plan.number_of_es_cells_passing_qc = 6
      default_mi_plan.valid?
      assert_equal 'Assigned - ES Cell QC Complete', default_mi_plan.status.name
    end

    should 'set status to "Aborted - ES Cell QC Failed" if number_of_es_cells_passing_qc is set to 0' do
      assert_equal 'Assigned', default_mi_plan.status.name

      default_mi_plan.number_of_es_cells_starting_qc = 5
      default_mi_plan.number_of_es_cells_passing_qc = 0
      default_mi_plan.valid?
      assert_equal 'Aborted - ES Cell QC Failed', default_mi_plan.status.name
    end

    should 'not do any status changes if it is currently Inactive' do
      default_mi_plan.update_attributes!(:is_active => false)
      assert_equal 'Inactive', default_mi_plan.status.name

      default_mi_plan.number_of_es_cells_passing_qc = 6
      default_mi_plan.valid?
      assert_equal 'Inactive', default_mi_plan.status.name
    end

    should 'set "Inactive" status when is_active is set to false ahead of other statuses' do
      default_mi_plan.update_attributes!(:is_active => false, :number_of_es_cells_starting_qc => 5)
      default_mi_plan.valid?
      assert_equal 'Inactive', default_mi_plan.status.name
    end

    should 'set "Withdrawn" status when #withdrawn is set to true' do
      default_mi_plan.status = MiPlan::Status['Conflict']
      default_mi_plan.save!
      assert_equal 'Conflict', default_mi_plan.status.name

      default_mi_plan.withdrawn = true
      assert default_mi_plan.valid?
      assert_equal true, default_mi_plan.withdrawn?
      assert_equal 'Withdrawn', default_mi_plan.status.name
    end

  end
end
