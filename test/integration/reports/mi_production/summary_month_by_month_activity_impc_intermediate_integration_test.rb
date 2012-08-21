# encoding: utf-8

require 'test_helper'

class Reports::MiProduction::SummaryMonthByMonthActivityImpcIntermediateIntegrationTest < Kermits2::IntegrationTest

  context 'Reports::MiProduction::SummaryMonthByMonthActivityImpcIntermediate' do
    should 'require the user to be logged in' do
      visit '/reports/mi_production/summary_month_by_month_activity_impc_intermediate'
      assert_login_page
    end

    context 'once logged in' do

      setup do
        visit '/users/logout'
        login
      end

      should 'allow users to visit the page' do
        visit '/reports/mi_production/summary_month_by_month_activity_impc_intermediate'
        assert_match '/reports/mi_production/summary_month_by_month_activity_impc_intermediate', current_url

        assert page.has_content? 'IMPC Summary Month by Month'
        assert page.has_css? 'a', :text => 'Download as CSV'

      end

    end

  end

end
