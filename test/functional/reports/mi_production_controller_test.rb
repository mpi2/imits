require 'test_helper'

class Reports::MiProductionControllerTest < ActionController::TestCase
  context 'Reports::MiProductionController' do

    context 'GET mi_production_detail' do
      should 'download report as CSV' do
        sign_in default_user
        Factory.create :mi_plan
        Reports::MiProduction::Intermediate.new.cache
        csv_data = Reports::MiProduction::Detail.generate.to_csv
        get :detail, :format => :csv
        assert_equal response.body, csv_data
        assert_equal csv_data.size.to_s, response.headers['Content-Length']
      end
    end

    context 'GET languishing' do
      should 'not have HTML in csv report' do
        Factory.create(:mi_plan, :consortium => Consortium.find_by_name!('BaSH'))
        Reports::MiProduction::Intermediate.new.cache
        sign_in default_user
        get :languishing, :format => :csv
        assert ! /<div/.match(response.body)
      end
    end

  end
end
