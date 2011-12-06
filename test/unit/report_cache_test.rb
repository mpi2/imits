require 'test_helper'

class ReportCacheTest < ActiveSupport::TestCase
  context 'ReportCache' do

    should 'have attributes' do
      assert_should have_db_column(:name).with_options(:null => false)
      assert_should have_db_index(:name).unique(true)
      assert_should have_db_column(:csv_data).with_options(:null => false)
    end

    context '#compact_timestamp' do
      should 'work' do
        cache = ReportCache.create!(:name => 'test', :csv_data => '')
        cache.update_attributes!(:updated_at => '2011-11-24 04:22:02 UTC')
        assert_equal '20111124042202', cache.compact_timestamp
        cache.update_attributes!(:csv_data => 'Test')
        assert_not_equal '20111124042202', cache.compact_timestamp
      end
    end

  end
end
