# encoding: utf-8

require 'test_helper'

class Reports::MiProduction::SummaryKomp2BriefTest <
    #Kermits2::JsIntegrationTest
  ActionDispatch::IntegrationTest
  
  DEBUG = false

  context 'Reports::MiProduction::SummaryKomp2Brief' do
    should 'require the user to be logged in' do
      visit '/reports/mi_production'
      assert_login_page
    end
  
    context 'once logged in' do

    setup do
      assert ! ReportCache.find_by_name('mi_production_intermediate')
      ReportCache.create!(
        :name => 'mi_production_intermediate',
        :csv_data => ProductionSummaryHelper::get_csv('summary by consortium')
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
      visit '/reports/production_summary5'
      assert_match '/reports/production_summary5', current_url

      assert_match 'Summary By Consortium', page.body
      assert_match 'Download as CSV', page.body
      
      # save_and_open_page if DEBUG
     
      sleep(10.seconds) if DEBUG
    end
    
    should 'allow users to visit the detail page & see entries' do
      visit '/reports/production_summary5?consortium=BaSH&type=Genotype+Confirmed+Mice'
      
      one = "/reports/production_summary5?consortium=BaSH&type=Genotype%20Confirmed%20Mice"
      other = "/reports/production_summary5?consortium=BaSH&type=Genotype+Confirmed+Mice"
      target = /\%20/.match(current_url) ? one : other
      assert_match target, current_url
      
      puts current_url if DEBUG
      
      assert_match 'Production Summary Detail', page.body
      assert_match 'Download as CSV', page.body
      
      # save_and_open_page if DEBUG
      
      sleep(10.seconds) if DEBUG
    end

  end

  end

end
