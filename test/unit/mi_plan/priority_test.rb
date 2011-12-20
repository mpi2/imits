# encoding: utf-8

require 'test_helper'

class MiPlan::PriorityTest < ActiveSupport::TestCase
  should validate_presence_of :name
  should validate_uniqueness_of :name
  should have_many :mi_plans

  should have_db_column(:name).with_options(:limit => 10, :null => false)
  should have_db_index(:name).unique(true)

  should 'be seeded correctly' do
    priority = MiPlan::Priority.find_by_name('High')
    assert_equal 'Estimated injection in the next 0-4 months', priority.description
  end
end
