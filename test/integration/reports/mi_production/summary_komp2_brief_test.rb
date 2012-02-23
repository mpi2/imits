# encoding: utf-8

require 'test_helper'

class Reports::MiProduction::SummaryKomp2BriefTest < Kermits2::IntegrationTest
  
  DEBUG = false

  context 'Reports::MiProduction::SummaryKomp2Brief' do
    should 'require the user to be logged in' do
      visit '/reports/mi_production'
      assert_login_page
    end
  
    context 'once logged in' do

    setup do
      assert ! ReportCache.find_by_name('mi_production_intermediate')
      Factory.create(:report_cache,
        :name => 'mi_production_intermediate',
        :data => ProductionSummaryHelper::get_csv('summary by consortium')
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

    should 'allow users to visit the page & see entries' do
      #visit '/reports/mi_production/summary_komp2_brief'
      #assert_match '/reports/mi_production/summary_komp2_brief', current_url
      #
      #assert_match 'Summary By Consortium', page.body
      #assert_match 'Download as CSV', page.body
      #
      ## save_and_open_page if DEBUG
      #
      #sleep(10.seconds) if DEBUG
    end
    
    should 'allow users to visit the detail page & see entries' do
      #visit '/reports/mi_production/summary_komp2_brief?consortium=BaSH&type=Genotype+Confirmed+Mice'
      #
      #one = "/reports/mi_production/summary_komp2_brief?consortium=BaSH&type=Genotype%20Confirmed%20Mice"
      #other = "/reports/mi_production/summary_komp2_brief?consortium=BaSH&type=Genotype+Confirmed+Mice"
      #target = /\%20/.match(current_url) ? one : other
      #assert_match target, current_url
      #
      #puts current_url if DEBUG
      #
      #assert_match 'Production Summary Detail', page.body
      #assert_match 'Download as CSV', page.body
      #
      ## save_and_open_page if DEBUG
      #
      #sleep(10.seconds) if DEBUG
    end

  end

  end

end
