require 'test_helper'

class QcStatusTest < ActiveSupport::TestCase
  context 'QAStatus' do
    should have_db_column(:description).with_options(:null => false)
    should have_db_index(:description).unique(true)

    should 'have seeded values' do
      assert QcStatus.find_by_description('na')
      assert QcStatus.find_by_description('fail')
      assert QcStatus.find_by_description('pass')
    end
  end
end
