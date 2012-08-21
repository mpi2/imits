# encoding: utf-8

require 'test_helper'

class Reports::MiProduction::ImpcGraphReportDisplayIntegrationTest < Kermits2::IntegrationTest

  DEBUG = false

  context 'Reports::MiProduction::ImpcGraphReportDisplay' do
    should 'require the user to be logged in' do
      visit '/reports/mi_production'
      assert_login_page
    end

    context 'once logged in' do

      setup do
        visit '/users/logout'
        login
      end

      should 'allow users to visit the page & see entries for ImpcGraphReportDisplay' do
        visit '/reports/mi_production/impc_graph_report_display'
        assert_match '/reports/mi_production/impc_graph_report_display', current_url

        assert page.has_content? 'KOMP2 Production Summaries'
      end

    end

  end

end
