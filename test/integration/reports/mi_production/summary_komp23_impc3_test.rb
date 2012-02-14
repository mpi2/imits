# encoding: utf-8

require 'test_helper'

class Reports::MiProduction::SummaryKomp23Impc3Test < ActionDispatch::IntegrationTest

  DEBUG = false

  context 'Reports::MiProduction::SummaryKomp23' do
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

        visit '/users/logout'
        login
      end

      should 'allow users to visit the page & see entries for komp23' do
        Reports::MiProduction::SummaryKomp23.new.cache
        visit '/reports/mi_production/summary_komp23'
        assert_match '/reports/mi_production/summary_komp23', current_url

        assert page.has_content? 'KOMP2 Production Summary'
        assert page.has_css? 'a', :text => 'Download as CSV'

        sleep(10.seconds) if DEBUG
      end

      should 'allow users to visit the page & see entries for impc3' do
        Reports::MiProduction::SummaryImpc3.new.cache
        visit '/reports/mi_production/summary_impc3'
        assert_match '/reports/mi_production/summary_impc3', current_url

        assert page.has_content? Reports::MiProduction::SummaryImpc3.report_title
        assert page.has_css? 'a', :text => 'Download as CSV'

        sleep(10.seconds) if DEBUG
      end

      should 'allow users to visit the full page & see entries'

      should 'allow users to visit the detail page & see entries' do
        visit "/reports/mi_production/summary_komp23?consortium=BaSH&type=Genotype%20Confirmed%20Mice"
        puts current_url if DEBUG

        assert page.has_content? 'Production Summary Detail'
        assert page.has_content? 'Download as CSV'

        # save_and_open_page if DEBUG

        sleep(10.seconds) if DEBUG
      end

    end

  end

end
