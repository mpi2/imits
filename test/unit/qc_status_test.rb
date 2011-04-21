require 'test_helper'

class QCStatusTest < ActiveSupport::TestCase
  context 'QAStatus' do
    should have_db_column(:description).with_options(:null => false)
    should have_db_index(:description).unique(true)

    should 'have seeded values' do
      assert QCStatus.find_by_description('na')
      assert QCStatus.find_by_description('fail')
      assert QCStatus.find_by_description('pass')
    end
  end
end
