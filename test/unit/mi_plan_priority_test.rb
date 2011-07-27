require 'test_helper'

class MiPlanPriorityTest < ActiveSupport::TestCase
  context 'MiPlanPriority' do

    should validate_presence_of :name
    should validate_uniqueness_of :name
    should have_many :mi_plans

    should have_db_column(:name).with_options(:null => false)
    should have_db_index(:name).unique(true)

  end
end
