# encoding: utf-8

require 'test_helper'

class Reports::MiProductionIntegrationTest < ActionDispatch::IntegrationTest
  
  DEBUG = false
  
  context 'MI production reports:' do

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

    context 'detailed MI production report' do
      should 'have link to cached report' do
        visit '/reports'
        click_link 'Detailed Report'
        assert page.has_css? "a[href='/reports/mi_production/detail.csv']"
      end

    end

    context 'summaries page' do
      should 'work' do
        visit '/reports/mi_production'
        assert page.has_css? 'h2', :text => 'MI Production Reports'
        assert page.has_css? 'a'

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
      end
    end

  end
end
