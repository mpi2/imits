require 'test_helper'

class Reports::MiProductionControllerTest < ActionController::TestCase
  context 'Reports::MiProductionController' do

    context 'GET mi_production_detail' do
      should 'download report as CSV' do
        sign_in default_user
        Factory.create :mi_plan
        Reports::MiProduction::Intermediate.generate_and_cache
        csv_data = Reports::MiProduction::Detail.generate.to_csv
        get :detail, :format => :csv
        assert_equal response.body, csv_data
        assert_equal csv_data.size.to_s, response.headers['Content-Length']
      end
    end


  end
end
