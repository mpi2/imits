require 'test_helper'

module Rake
  module Db
    class FlushCachesTest < ExternalScriptTestCase
      context 'rake db:flush_caches' do

        should 'flush report caches' do
          ReportCache.create! :name => 'temp', :csv_data => 'a', :html_data => '<div>a</div>'
          run_script 'rake db:flush_caches'
          sleep 3
          assert_equal 0, ReportCache.count
        end

      end
    end
  end
end
