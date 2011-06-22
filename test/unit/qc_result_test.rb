require 'test_helper'

class QcResultTest < ActiveSupport::TestCase
  context 'QcResult' do
    should have_db_column(:description).with_options(:null => false)
    should have_db_index(:description).unique(true)

    should 'have seeded values' do
      assert QcResult.find_by_description('na')
      assert QcResult.find_by_description('fail')
      assert QcResult.find_by_description('pass')
    end
  end
end
