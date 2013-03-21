require 'test_helper'

class MiPlan::EsCellQcTest < ActiveSupport::TestCase
  context 'EsCellQc' do
    context 'attribute tests:' do
      should 'have associations' do
        assert_should belong_to :mi_plan
      end

      should 'have db columns' do
        assert_should have_db_column(:number_starting_qc).of_type(:integer)
        assert_should have_db_column(:number_passing_qc).of_type(:integer)
        assert_should have_db_column(:mi_plan_id).of_type(:integer)
      end
    end
  end
end
