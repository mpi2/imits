require 'test_helper'

class ReportCachesControllerTest < ActionController::TestCase
  context 'ReportCachesController' do

    should 'require authentication' do
      get :show, :id => 'test', :format => :csv
      assert_false response.success?
    end

    context 'GET show' do
      setup do
        sign_in default_user
      end

      should 'respond with valid report if id is correct' do
        cache = Factory.create :report_cache, :name => 'test_report', :csv_data => ['Test', 'Data'].to_csv
        cache.update_attributes!(:updated_at => '2011-12-31 23:59:59 UTC')

        get :show, :id => 'test_report', :format => :csv
        assert_equal "Test,Data\n", response.body
        assert_equal 'attachment; filename=test_report-20111231235959.csv',
                response.headers['Content-Disposition']
        assert_equal cache.csv_data.size.to_s,
                response.headers['Content-Length']
      end

      should 'respond with missing 404 if report not found' do
        assert_equal 0, ReportCache.count
        get :show, :id => 'test_report', :format => :csv
        assert_equal 404, response.status
      end
    end

  end
end
