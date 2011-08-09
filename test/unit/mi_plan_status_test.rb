# encoding: utf-8

require 'test_helper'

class MiPlanStatusTest < ActiveSupport::TestCase
  should validate_presence_of :name
  should validate_uniqueness_of :name
  should have_many :mi_plans

  should have_db_column(:name).with_options(:limit => 50, :null => false)
  should have_db_index(:name).unique(true)

  should have_db_column(:description).with_options(:limit => 255)
end
