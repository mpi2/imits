# encoding: utf-8

require 'test_helper'

class MiPlan::StatusTest < ActiveSupport::TestCase
  should validate_presence_of :name
  should validate_uniqueness_of :name

  should have_db_column(:name).with_options(:limit => 50, :null => false)
  should have_db_index(:name).unique(true)

  should have_db_column(:description).with_options(:limit => 255)

  should have_db_column(:order_by)

  should 'include StatusInterface' do
    assert_include MiPlan::Status.ancestors, StatusInterface
  end

  should 'have ::all_non_assigned' do
    expected = [
      'Interest',
      'Conflict',
      'Inspect - GLT Mouse',
      'Inspect - MI Attempt',
      'Inspect - Conflict',
      'Aborted - ES Cell QC Failed',
      'Withdrawn'
    ].sort
    assert_equal expected, MiPlan::Status.all_non_assigned.map(&:name).sort
  end

  should 'have ::all_assigned' do
    expected = [
      'Assigned',
      'Assigned - ES Cell QC In Progress',
      'Assigned - ES Cell QC Complete'
    ].sort
    assert_equal expected, MiPlan::Status.all_assigned.map(&:name).sort
  end

end
