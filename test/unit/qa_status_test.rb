require 'test_helper'

class QAStatusTest < ActiveSupport::TestCase
  context 'QAStatus' do
    should have_db_column(:description).with_options(:null => false)
    should have_db_index(:description).unique(true)

    should 'have seeded values' do
      assert QAStatus.find_by_description('na')
      assert QAStatus.find_by_description('fail')
      assert QAStatus.find_by_description('pass')
    end
  end
end
