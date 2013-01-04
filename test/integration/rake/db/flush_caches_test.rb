require 'test_helper'

module Rake
  module Db
    class FlushCachesTest < TarMits::ExternalScriptTestCase
      context 'rake db:flush_caches' do

        should 'flush report caches' do
          ReportCache.create! :name => 'temp', :data => 'a', :format => 'csv'
          run_script 'rake db:flush_caches'
          assert_equal 0, ReportCache.count
        end

      end
    end
  end
end
