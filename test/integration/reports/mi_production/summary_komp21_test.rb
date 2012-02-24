# encoding: utf-8

require 'test_helper'

class Reports::MiProduction::SummaryKomp21Test < ActionDispatch::IntegrationTest

  DEBUG = false

  context 'Reports::MiProduction::SummaryKomp21' do
    should 'require the user to be logged in' do
      visit '/reports/mi_production'
      assert_login_page
    end

    context 'once logged in' do

    setup do
      assert ! ReportCache.find_by_name('mi_production_intermediate')
      Factory.create(:report_cache,
        :name => 'mi_production_intermediate',
        :data => ProductionSummaryHelper::get_csv('komp2')
      )
      assert ReportCache.find_by_name('mi_production_intermediate')
      report = ReportCache.find_by_name!('mi_production_intermediate').to_table

      puts 'SETUP:' if DEBUG
      puts report.to_s if DEBUG
      assert report

      create_common_test_objects
      visit '/users/logout'
      login
    end

    should 'allow users to visit the page & see entries'
    should 'allow users to visit the detail page & see entries'
  end

  end

end
