# encoding: utf-8

require 'test_helper'

class ReportCacheTest < ActiveSupport::TestCase
  context 'ReportCache' do

    should 'have attributes' do
      assert_should have_db_column(:name).with_options(:null => false)
      assert_should have_db_index(:name).unique(true)
      assert_should have_db_column(:data).with_options(:null => false)
      assert_should have_db_column(:format).with_options(:null => false)
    end

    context '#compact_timestamp' do
      should 'work' do
        cache = ReportCache.create!(:name => 'test', :data => '',
          :format => 'csv')
        cache.update_attributes!(:updated_at => '2011-11-24 04:22:02 UTC')
        assert_equal '20111124042202', cache.compact_timestamp
        cache.update_attributes!(:data => 'Test')
        assert_not_equal '20111124042202', cache.compact_timestamp
      end
    end

    context '#to_table' do
      should 'convert CSV report into a Ruport table' do
        cache = ReportCache.create!(:name => 'test', :data => "col1,col2\na,b\nd,e\n",
          :format => 'csv')
        expected = Ruport::Data::Table.new(
          :column_names => ['col1', 'col2'],
          :data => [
            ['a', 'b'],
            ['d', 'e']
          ]
        )
        assert_equal expected.to_csv, cache.to_table.to_csv
      end

      should 'fail if HTML report' do
        cache = ReportCache.create!(:name => 'test', :data => "<div></div>",
          :format => 'html')
        assert_raise(ReportCache::Error) { cache.to_table }
      end
    end

  end
end
