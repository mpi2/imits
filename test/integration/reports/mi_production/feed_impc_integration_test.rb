# encoding: utf-8

require 'test_helper'

class Reports::MiProduction::FeedImpcIntegrationTest < TarMits::IntegrationTest

  DEBUG = false

  context 'Reports::MiProduction::FeedImpc' do

    setup do
      assert ! ReportCache.find_by_name('mi_production_intermediate')
      Factory.create(:report_cache,
        :name => 'mi_production_intermediate',
        :data => ProductionSummaryHelper::get_csv('feed int')
      )
      assert ReportCache.find_by_name('mi_production_intermediate')
      report = ReportCache.find_by_name!('mi_production_intermediate').to_table

      puts 'SETUP:' if DEBUG
      puts report.to_s if DEBUG
      assert report
    end

    should 'allow users to visit the feed demo page & see entries (without login)' do
      visit '/reports/mi_production/summary_by_consortium_and_accumulated_status'
      assert_match '/reports/mi_production/summary_by_consortium_and_accumulated_status', current_url

      assert_match 'Production Summary 1 (feed)', page.body
      assert_match 'Download as CSV', page.body

      # save_and_open_page if DEBUG

      sleep(10.seconds) if DEBUG

    end

    should 'allow users to visit the feed demo detail page & see entries (without login)' do
      visit '/reports/mi_production/summary_by_consortium_and_accumulated_status?consortium=DTCC-Legacy&type=Microinjection+in+progress'

      one = "/reports/mi_production/summary_by_consortium_and_accumulated_status?consortium=DTCC-Legacy&type=Microinjection%20in%20progress"
      other = "reports/mi_production/summary_by_consortium_and_accumulated_status?consortium=DTCC-Legacy&type=Microinjection+in+progress"
      target = /\%20/.match(current_url) ? one : other
      assert_match target, current_url

      puts current_url if DEBUG

      assert_match 'Production Summary 1 Detail (feed)', page.body
      assert_match 'Download as CSV', page.body
      assert_match 'ikmc-favicon.ico', page.body

      # save_and_open_page if DEBUG

      sleep(10.seconds) if DEBUG

    end

    should 'allow users to visit the feed demo detail page & see entries - just table (without login)' do
      visit '/reports/mi_production/summary_by_consortium_and_accumulated_status&feed=true'
      assert_match '/reports/mi_production/summary_by_consortium_and_accumulated_status&feed=true', current_url

      assert page.body && page.body.length > 0

      puts page.body if DEBUG

      # save_and_open_page if DEBUG

      sleep(10.seconds) if DEBUG
    end

    should 'allow users to visit the feed demo detail page & see entries - just table (without login)' do
      visit '/reports/mi_production/summary_by_consortium_and_accumulated_status?consortium=DTCC-Legacy&type=Microinjection+in+progress&feed=true'

      one = "/reports/mi_production/summary_by_consortium_and_accumulated_status?consortium=DTCC-Legacy&type=Microinjection%20in%20progress&feed=true"
      other = "reports/mi_production/summary_by_consortium_and_accumulated_status?consortium=DTCC-Legacy&type=Microinjection+in+progress&feed=true"
      target = /\%20/.match(current_url) ? one : other
      assert_match target, current_url

      puts page.body if DEBUG

      assert page.body && page.body.length > 0

      # save_and_open_page if DEBUG

      sleep(10.seconds) if DEBUG
    end

  end

end
