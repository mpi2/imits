# encoding: utf-8

require 'test_helper'

class Reports::MiProduction::PageCheckTest < ActionDispatch::IntegrationTest
  
  DEBUG = false

  context 'Reports::MiProduction::PageCheck' do
    should 'require the user to be logged in' do
      visit '/reports/mi_production'
      assert_login_page
    end
  
    context 'once logged in' do

    setup do
      assert ! ReportCache.find_by_name('mi_production_intermediate')
      ReportCache.create!(
        :name => 'mi_production_intermediate',
        :csv_data => ProductionSummaryHelper::get_csv('feed int')
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

    should 'allow users to visit the page click to reports' do
      visit '/reports/mi_production/'
      assert_match '/reports/mi_production/', current_url
      
      click_array = [
        'mousephenotype.org feed',
        'Summary Group by Consortium',
        'Summary Group by Consortium and Priority',
        'MGP Report',
        'KOMP2 Report 1',
        'KOMP2 Report 2'
      ]
            
      click_array.each do |name|
        click_link name
        sleep(10.seconds) if DEBUG
        visit '/reports/mi_production/'
      end

      # save_and_open_page if DEBUG
     
    end
    
  end

  end

end
