require 'test_helper'

class QcResultTest < ActiveSupport::TestCase
  context 'QcResult' do

    should 'have description' do
      assert_should have_db_column(:description).with_options(:null => false)
      assert_should have_db_index(:description).unique(true)
    end

    should 'have seeded values' do
      assert QcResult.find_by_description('na')
      assert QcResult.find_by_description('fail')
      assert QcResult.find_by_description('pass')
    end

    should 'have access helpers' do
      assert_equal 'na', QcResult.na.description
      assert_equal 'pass', QcResult.pass.description
      assert_equal 'fail', QcResult.fail.description
    end

  end
end
