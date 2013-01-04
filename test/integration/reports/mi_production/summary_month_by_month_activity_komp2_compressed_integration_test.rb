# encoding: utf-8

require 'test_helper'

class Reports::MiProduction::SummaryMonthByMonthActivityKomp2CompressedIntegrationTest < TarMits::IntegrationTest

  DEBUG = false

  context 'Reports::MiProduction::SummaryMonthByMonthActivityKomp2Compressed' do
    should 'require the user to be logged in' do
      visit '/reports/mi_production/summary_month_by_month_activity_komp2_compressed'
      assert_login_page
    end

    context 'once logged in' do

      setup do
        visit '/users/logout'
        login
      end

      should 'allow users to visit the page & see entries for komp23' do
        visit '/reports/mi_production/summary_month_by_month_activity_komp2_compressed'
        assert_match '/reports/mi_production/summary_month_by_month_activity_komp2_compressed', current_url

        assert page.has_content? 'KOMP2 Summary Month by Month'
        assert page.has_css? 'a', :text => 'Download as CSV'

      end

    end

  end

end
