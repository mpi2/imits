# encoding: utf-8

require 'test_helper'

class Reports::ConsortiumPrioritySummaryTest < ActionDispatch::IntegrationTest

  extend Reports::Helper
  include Reports::Helper
  
  DEBUG = true

  TEST_CSV = <<-"CSV"
"Consortium","Sub-Project","Priority","Production Centre","Gene","Status","Assigned Date","Assigned - ES Cell QC In Progress Date","Assigned - ES Cell QC Complete Date","Micro-injection in progress Date","Genotype confirmed Date","Micro-injection aborted Date"
"BaSH",,"High","BCM","Fxr2","Aborted - ES Cell QC Failed","2011-10-10","2011-11-04",,,,
"BaSH",,"High","BCM","Bmp4","Assigned","2011-10-25",,,,,
"BaSH",,"High","BCM","Bcl7b","Assigned - ES Cell QC Complete","2011-10-10","2011-11-04","2011-11-25",,,
"BaSH",,"High","BCM","Anks1","Assigned - ES Cell QC In Progress","2011-10-25","2011-11-16",,,,
"BaSH",,"Medium","BCM","Mapk4","Conflict",,,,,,
"BaSH",,"High","BCM","Prdm14","Genotype confirmed","2011-10-10","2011-11-22",,"2011-12-02","2011-12-02",
"BaSH",,"High","BCM","Zfp111","Inspect - Conflict",,,,,,
"BaSH",,"High","MRC - Harwell","Atg3","Inspect - GLT Mouse",,,,,,
"BaSH",,"High","BCM","Fam122c","Inspect - MI Attempt",,,,,,
"BaSH",,"High","MRC - Harwell","Cbx2","Interest",,,,,,
"BaSH",,"Low","WTSI","Apc2","Micro-injection aborted","2011-12-01",,,"2011-09-05",,"2011-12-02"
"BaSH",,"High","BCM","Alg10b","Micro-injection in progress","2011-10-10",,,"2011-09-08",,
"BaSH",,"High","MRC - Harwell","Lyplal1","Withdrawn",,,,,,
  CSV

  context 'ConsortiumPrioritySummary:' do

    setup do
      assert ! ReportCache.find_by_name('mi_production_detail')
      ReportCache.create!(
        :name => 'mi_production_detail',
        :csv_data => TEST_CSV
      )
      assert ReportCache.find_by_name('mi_production_detail')
      
      report = get_cached_report('mi_production_detail')    
    end

    should 'allow users to visit the feed demo page & see entries (without login)' do
      visit '/reports/production_summary1'
      assert_match '/reports/production_summary1', current_url

      assert_match 'Production Summary 1 (feed)', page.body

      assert page.has_css?('div.report tr:nth-child(1) th:nth-child(1)', :text => 'Consortium')
      assert page.has_css?('div.report tr:nth-child(1) th:nth-child(2)', :text => 'All')
      assert page.has_css?('div.report tr:nth-child(1) th:nth-child(3)', :text => 'Activity')
      assert page.has_css?('div.report tr:nth-child(1) th:nth-child(4)', :text => 'Mice in production')
      assert page.has_css?('div.report tr:nth-child(1) th:nth-child(5)', :text => 'GLT Mice')

      assert page.has_css?('div.report tr:nth-child(2) td:nth-child(1)', :text => 'BaSH')
      assert page.has_css?('div.report tr:nth-child(2) td:nth-child(2)', :text => '10')
      assert page.has_css?('div.report tr:nth-child(2) td:nth-child(3)', :text => '4')
      assert page.has_css?('div.report tr:nth-child(2) td:nth-child(4)', :text => '2')
      assert page.has_css?('div.report tr:nth-child(2) td:nth-child(5)', :text => '1')
    end
    
    # gives just table using curl http://localhost:3000/reports/production_summary1?feed=true
    
    should 'allow users to visit the feed demo detail page & see entries (without login)' do
      visit '/reports/production_summary1?consortium=BaSH&type=Mice+in+production'
      assert_match '/reports/production_summary1?consortium=BaSH&type=Mice%20in%20production', current_url

      column_name = ['Consortium', 'Sub-Project', 'Priority', 'Production Centre', 'Gene', 'Status', 'Assigned Date',
        'Assigned - ES Cell QC In Progress Date', 'Assigned - ES Cell QC Complete Date', 'Micro-injection in progress Date',
        'Genotype confirmed Date', 'Micro-injection aborted Date']
      
      counter = 1
      column_name.each do |name|
        assert page.has_css?("div.report tr:nth-child(1) th:nth-child(#{counter})", :text => column_name[counter-1])
        counter += 1
      end

      column_name = ['BaSH', '', 'High', 'BCM', 'Prdm14', 'Genotype confirmed', '2011-10-10', '2011-11-22', '', '2011-12-02', '2011-12-02', '']

      counter = 1
      column_name.each do |name|
        assert page.has_css?("div.report tr:nth-child(2) td:nth-child(#{counter})", :text => column_name[counter-1])
        counter += 1
      end
      #      save_and_open_page if DEBUG
    end

    should 'allow users to visit the feed demo url & see text (without login)' do
      visit '/reports/production_summary1?feed=true'
      assert_match '/reports/production_summary1?feed=true', current_url
      assert page.body.length > 0
    end
    
    #re4@deskpro101067:~/dev/imits$ curl http://localhost:3000/reports/production_summary1?feed=true&consortium=MGP-KOMP&type=GLT+Mice&
    #http://www.example.com/reports/production_summary1?feed=true&consortium=MGP-KOMP&type=GLT%20Mice

    # gives just table using curl http://localhost:3000/reports/production_summary1?feed=true&consortium=BaSH&type=Mice+in+production
    
    should 'allow users to visit the feed detail demo url & see text (without login)' do
      
      url = '/reports/production_summary1?feed=true&consortium=BaSH&type=Mice+in+production'
      url2 = '/production_summary1?feed=true&consortium=BaSH&type=Mice%20in%20production'
      
      visit url
      assert_match url2, current_url
      assert page.body.length > 0
      # puts 'URL: ' + current_url
      #   puts page.body
    end
    
    context 'once logged in' do
      setup do
        create_common_test_objects
        visit '/users/logout'
        login
      end

      should 'allow users to visit the prod summary 2 page & see entries' do
        visit '/reports/production_summary2'
        assert_match '/reports/production_summary2', current_url
  
        #        save_and_open_page if DEBUG

        assert_match 'Production Summary 2', page.body
        
        column_name = ['Consortium', 'Priority', 'All', 'ES QC started', 'ES QC finished', 'MI in progress', 'Aborted', 'GLT Mice', 'Pipeline efficiency (%)']

        counter = 1
        column_name.each do |name|
          assert page.has_css?("div.report tr:nth-child(1) th:nth-child(#{counter})", :text => column_name[counter-1])
          counter += 1
        end
      end
      
      should 'allow users to visit the prod summary 2 detail page & see entries' do
        #http://localhost:3000/reports/production_summary2?consortium=MGP-KOMP&type=GLT%20Mice&priority=High
        url = '/reports/production_summary2?consortium=BaSH&type=GLT%20Mice&priority=High'
        url2 = '/reports/production_summary2?consortium=BaSH&type=GLT%20Mice&priority=High'
        
        visit url
        assert_match url2, current_url
  
        save_and_open_page if DEBUG

        assert_match 'Production Summary Detail 2', page.body
        
        column_name = [
          'Consortium',
          'Sub-Project',
          'Priority',
          'Production Centre',
          'Gene',
          'Status',
          'Assigned Date',
          'Assigned - ES Cell QC In Progress Date',
          'Assigned - ES Cell QC Complete Date',
          'Micro-injection in progress Date',
          'Genotype confirmed Date',
          'Micro-injection aborted Date'
        ]

        counter = 1
        column_name.each do |name|
          assert page.has_css?("div.report tr:nth-child(1) th:nth-child(#{counter})", :text => column_name[counter-1])
          counter += 1
        end
      end
      
    end

  end
end
