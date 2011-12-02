require 'test_helper'

class ReportCacheTest < ActiveSupport::TestCase
  context 'ReportCache' do

    should 'have attributes' do
      assert_should have_db_column(:name).with_options(:null => false)
      assert_should have_db_index(:name).unique(true)
      assert_should have_db_column(:csv_data).with_options(:null => false)
    end

  end
end
