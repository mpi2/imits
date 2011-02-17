require 'test_helper'

class NetzkeTest < ActiveSupport::TestCase
  context 'netzke_temp_table' do
    should 'not be created in the main database, but in its own one' do
      assert_true NetzkePersistentArrayAutoModel.connection.table_exists?('netzke_temp_table')
      assert_false EmiAttempt.connection.table_exists?('netzke_temp_table')
    end

    should 'be of different type to rest of db connections' do
      assert_kind_of ActiveRecord::ConnectionAdapters::PostgreSQLAdapter, EmiAttempt.connection
      assert_kind_of ActiveRecord::ConnectionAdapters::SQLite3Adapter, NetzkePersistentArrayAutoModel.connection
    end
  end
end
