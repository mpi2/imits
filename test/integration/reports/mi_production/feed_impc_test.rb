# encoding: utf-8

require 'test_helper'

class Reports::MiProduction::FeedImpcTest < Kermits2::JsIntegrationTest
  #ActionDispatch::IntegrationTest

  extend Reports::Helper
  include Reports::Helper

  DEBUG = false

  TEST_CSV = <<-"CSV"
"Consortium","Sub-Project","Priority","Production Centre","Gene","MGI Accession ID","Overall Status","MiPlan Status","MiAttempt Status","PhenotypeAttempt Status","IKMC Project ID","Mutation Sub-Type","Allele Symbol","Genetic Background","Assigned Date","Assigned - ES Cell QC In Progress Date","Assigned - ES Cell QC Complete Date","Micro-injection in progress Date","Genotype confirmed Date","Micro-injection aborted Date","Phenotype Attempt Registered Date","Rederivation Started Date","Rederivation Complete Date","Cre Excision Started Date","Cre Excision Complete Date","Phenotyping Started Date","Phenotyping Complete Date","Phenotype Attempt Aborted Date"
"BaSH",,"High","BCM","1700093J21Rik","MGI:1921546","Assigned - ES Cell QC In Progress","Assigned - ES Cell QC In Progress",,,,,,,"2011-10-10","2011-11-16",,,,,,,,,,,,
"BaSH",,"High","BCM","Akt1s1","MGI:1914855","Micro-injection in progress","Assigned","Micro-injection in progress",,28913,"conditional_ready","Akt1s1<sup>tm1a(EUCOMM)Wtsi</sup>","C57BL/6N","2011-10-10",,,"2011-09-27",,,,,,,,,,
"BaSH",,"High","BCM","Alg10b","MGI:2146159","Genotype confirmed","Assigned","Genotype confirmed",,"VG10825","deletion","Alg10b<sup>tm1(KOMP)Vlcg</sup>","C57BL/6N","2011-10-10",,,"2011-09-08","2012-01-07",,,,,,,,,
"BaSH",,"High","BCM","Acot6","MGI:1921287","Phenotyping Complete","Assigned","Genotype confirmed","Phenotyping Complete",31219,"conditional_ready","Acot6<sup>tm1a(KOMP)Wtsi</sup>","C57BL/6NTac/Den","2008-06-11",,,"2008-06-11","2008-12-29",,"2012-01-09",,,"2012-01-09",,"2012-01-09","2012-01-09",
"DTCC-Legacy",,"High","UCD","0610007L01Rik","MGI:1918917","Genotype confirmed","Assigned","Genotype confirmed",,"VG13171","deletion","0610007L01Rik<sup>tm1(KOMP)Vlcg</sup>",,"2010-04-01",,,"2010-04-01","2010-04-01"
"DTCC-Legacy",,"High","UCD","1300002K09Rik","MGI:1921402","Genotype confirmed","Assigned","Genotype confirmed",,29982,"conditional_ready","1300002K09Rik<sup>tm1a(KOMP)Wtsi</sup>",,"2009-07-01",,,"2009-08-25","2010-07-20"
"DTCC-Legacy",,"High","UCD","1700003F12Rik","MGI:1922730","Genotype confirmed","Assigned","Genotype confirmed",,"VG10243","deletion","1700003F12Rik<sup>tm1(KOMP)Vlcg</sup>",,"2011-10-19",,,"2011-06-09","2011-10-19"
"DTCC-Legacy",,"High","UCD","1700011F03Rik","MGI:1921471","Genotype confirmed","Assigned","Genotype confirmed",,"VG11827","deletion","1700011F03Rik<sup>tm1(KOMP)Vlcg</sup>",,"2010-03-05",,,"2010-03-05","2010-03-05"
"DTCC-Legacy",,"High","UCD","1810027O10Rik","MGI:1916436","Genotype confirmed","Assigned","Genotype confirmed",,"VG11870","deletion","1810027O10Rik<sup>tm1(KOMP)Vlcg</sup>",,"2010-03-30",,,"2010-03-30","2010-03-30"
  CSV

  context 'Reports::MiProduction::FeedImpc:' do

    setup do
      assert ! ReportCache.find_by_name('mi_production_intermediate')
      ReportCache.create!(
        :name => 'mi_production_intermediate',
        :csv_data => TEST_CSV
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
    
    #http://localhost:3000/reports/mi_production/summary_by_consortium_and_accumulated_status?consortium=DTCC-Legacy&type=Microinjection+in+progress
    
    should 'allow users to visit the feed demo detail page & see entries (without login)' do
      visit '/reports/mi_production/summary_by_consortium_and_accumulated_status?consortium=DTCC-Legacy&type=Microinjection+in+progress'
    
      #assert_match 'http://www.example.com/reports/mi_production/summary_by_consortium_and_accumulated_status?consortium=BaSH&type=All%20Projects', current_url
      #assert_match "http://127.0.0.1:54233/reports/mi_production/summary_by_consortium_and_accumulated_status?consortium=DTCC-Legacy&type=Microinjection+in+progress", current_url
      #assert_match "reports/mi_production/summary_by_consortium_and_accumulated_status?consortium=DTCC-Legacy&type=Microinjection+in+progress", current_url
      one = "/reports/mi_production/summary_by_consortium_and_accumulated_status?consortium=DTCC-Legacy&type=Microinjection%20in%20progress"
      other = "reports/mi_production/summary_by_consortium_and_accumulated_status?consortium=DTCC-Legacy&type=Microinjection+in+progress"
      target = /\%20/.match(current_url) ? one : other
      assert_match target, current_url
      
    puts current_url if DEBUG
  
      assert_match 'Production Summary 1 Detail (feed)', page.body
      assert_match 'Download as CSV', page.body
      assert_match 'ikmc-favicon.ico', page.body      
      
    #  save_and_open_page if DEBUG
     sleep(10.seconds) if DEBUG

    end    
  
    should 'allow users to visit the feed demo detail page & see entries -just table (without login)'
    should 'allow users to visit the feed demo detail page & see entries -just table (without login)' 
    
  end



  
#  DEBUG = false
#
#  TEST_CSV = <<-"CSV"
#"Consortium","Sub-Project","Priority","Production Centre","Gene","Status","Assigned Date","Assigned - ES Cell QC In Progress Date","Assigned - ES Cell QC Complete Date","Micro-injection in progress Date","Genotype confirmed Date","Micro-injection aborted Date"
#"BaSH",,"High","BCM","Fxr2","Aborted - ES Cell QC Failed","2011-10-10","2011-11-04",,,,
#"BaSH",,"High","BCM","Bmp4","Assigned","2011-10-25",,,,,
#"BaSH",,"High","BCM","Bcl7b","Assigned - ES Cell QC Complete","2011-10-10","2011-11-04","2011-11-25",,,
#"BaSH",,"High","BCM","Anks1","Assigned - ES Cell QC In Progress","2011-10-25","2011-11-16",,,,
#"BaSH",,"Medium","BCM","Mapk4","Conflict",,,,,,
#"BaSH",,"High","BCM","Prdm14","Genotype confirmed","2011-10-10","2011-11-22",,"2011-12-02","2011-12-02",
#"BaSH",,"High","BCM","Zfp111","Inspect - Conflict",,,,,,
#"BaSH",,"High","MRC - Harwell","Atg3","Inspect - GLT Mouse",,,,,,
#"BaSH",,"High","BCM","Fam122c","Inspect - MI Attempt",,,,,,
#"BaSH",,"High","MRC - Harwell","Cbx2","Interest",,,,,,
#"BaSH",,"Low","WTSI","Apc2","Micro-injection aborted","2011-12-01",,,"2011-09-05",,"2011-12-02"
#"BaSH",,"High","BCM","Alg10b","Micro-injection in progress","2011-10-10",,,"2011-09-08",,
#"BaSH",,"High","MRC - Harwell","Lyplal1","Withdrawn",,,,,,
#  CSV
#
#  context 'ConsortiumPrioritySummary:' do
#
#    COLUMN_NAMES_SUMMARY_PAGE_1 = ['Consortium', 'All', 'Activity', 'Mice in production', 'GLT Mice']
#    COLUMN_VALUES_SUMMARY_PAGE_1 = ['BaSH', '10', '4', '2', '1']
#    COLUMN_NAMES_SUMMARY_DETAIL_PAGE_1 = ['Consortium', 'Sub-Project', 'Priority', 'Production Centre', 'Gene', 'Status', 'Assigned Date',
#      'Assigned - ES Cell QC In Progress Date', 'Assigned - ES Cell QC Complete Date', 'Micro-injection in progress Date',
#      'Genotype confirmed Date', 'Micro-injection aborted Date']
#    COLUMN_VALUES_SUMMARY_DETAIL_PAGE_1 = ['BaSH', '', 'High', 'BCM', 'Prdm14', 'Genotype confirmed', '2011-10-10', '2011-11-22', '', '2011-12-02', '2011-12-02', '']
#
#    COLUMN_NAMES_SUMMARY_PAGE_2 = ['Consortium', 'Priority', 'All', 'ES QC started', 'ES QC finished', 'MI in progress', 'Aborted', 'GLT Mice', 'Pipeline efficiency (%)']
#    COLUMN_NAMES_SUMMARY_DETAIL_PAGE_2 = [
#      'Consortium', 'Sub-Project', 'Priority', 'Production Centre', 'Gene', 'Status', 'Assigned Date', 'Assigned - ES Cell QC In Progress Date',
#      'Assigned - ES Cell QC Complete Date', 'Micro-injection in progress Date', 'Genotype confirmed Date','Micro-injection aborted Date'
#    ]
#
#    setup do
#      assert ! ReportCache.find_by_name('mi_production_detail')
#      ReportCache.create!(
#        :name => 'mi_production_detail',
#        :csv_data => TEST_CSV
#      )
#      assert ReportCache.find_by_name('mi_production_detail')
#      report = get_cached_report('mi_production_detail')    
#      assert report
#    end
#
#    should 'allow users to visit the feed demo page & see entries (without login)' do
#      visit '/reports/production_summary1'
#      assert_match '/reports/production_summary1', current_url
#
#      assert_match 'Production Summary 1 (feed)', page.body
#      
#      counter = 1
#      COLUMN_NAMES_SUMMARY_PAGE_1.each do |name|
#        assert page.has_css?("div.report tr:nth-child(1) th:nth-child(#{counter})", :text => COLUMN_NAMES_SUMMARY_PAGE_1[counter-1])
#        assert page.has_css?("div.report tr:nth-child(2) td:nth-child(#{counter})", :text => COLUMN_VALUES_SUMMARY_PAGE_1[counter-1])
#        counter += 1
#      end
#    end
#    
#    # gives just table using curl http://localhost:3000/reports/production_summary1?feed=true
#    
#    should 'allow users to visit the feed demo detail page & see entries (without login)' do
#      visit '/reports/production_summary1?consortium=BaSH&type=Mice+in+production'
#      assert_match '/reports/production_summary1?consortium=BaSH&type=Mice%20in%20production', current_url
#
#      #column_name = ['Consortium', 'Sub-Project', 'Priority', 'Production Centre', 'Gene', 'Status', 'Assigned Date',
#      #  'Assigned - ES Cell QC In Progress Date', 'Assigned - ES Cell QC Complete Date', 'Micro-injection in progress Date',
#      #  'Genotype confirmed Date', 'Micro-injection aborted Date']
#      
#      counter = 1
#      COLUMN_NAMES_SUMMARY_DETAIL_PAGE_1.each do |name|
#        assert page.has_css?("div.report tr:nth-child(1) th:nth-child(#{counter})", :text => COLUMN_NAMES_SUMMARY_DETAIL_PAGE_1[counter-1])
#        assert page.has_css?("div.report tr:nth-child(2) td:nth-child(#{counter})", :text => COLUMN_VALUES_SUMMARY_DETAIL_PAGE_1[counter-1])
#        counter += 1
#      end
#
#      #      column_name = ['BaSH', '', 'High', 'BCM', 'Prdm14', 'Genotype confirmed', '2011-10-10', '2011-11-22', '', '2011-12-02', '2011-12-02', '']
#
#      #counter = 1
#      #COLUMN_VALUES_SUMMARY_DETAIL_PAGE_1.each do |name|
#      #  assert page.has_css?("div.report tr:nth-child(2) td:nth-child(#{counter})", :text => COLUMN_VALUES_SUMMARY_DETAIL_PAGE_1[counter-1])
#      #  counter += 1
#      #end
#    end
#
#    should 'allow users to visit the feed demo url & see text (without login)' do
#      visit '/reports/production_summary1?feed=true'
#      assert_match '/reports/production_summary1?feed=true', current_url
#      assert page.body.length > 0
#    end
#    
#    # gives just table using curl http://localhost:3000/reports/production_summary1?feed=true&consortium=BaSH&type=Mice+in+production
#    
#    should 'allow users to visit the feed detail demo url & see text (without login)' do
#      
#      url = '/reports/production_summary1?feed=true&consortium=BaSH&type=Mice+in+production'
#      url2 = '/production_summary1?feed=true&consortium=BaSH&type=Mice%20in%20production'
#      
#      visit url
#      assert_match url2, current_url
#      assert page.body.length > 0
#    end
#    
#    context 'once logged in' do
#      setup do
#        create_common_test_objects
#        visit '/users/logout'
#        login
#      end
#
#      should 'allow users to visit the prod summary 2 page & see entries' do
#        visit '/reports/production_summary2'
#        assert_match '/reports/production_summary2', current_url
#  
#        assert_match 'Production Summary 2', page.body
#        assert_match 'Download as CSV', page.body
#        
#        #        column_name = ['Consortium', 'Priority', 'All', 'ES QC started', 'ES QC finished', 'MI in progress', 'Aborted', 'GLT Mice', 'Pipeline efficiency (%)']
#
#        counter = 1
#        COLUMN_NAMES_SUMMARY_PAGE_2.each do |name|
#          assert page.has_css?("div.report tr:nth-child(1) th:nth-child(#{counter})", :text => COLUMN_NAMES_SUMMARY_PAGE_2[counter-1])
#          counter += 1
#        end
#      end
#      
#      should 'allow users to visit the prod summary 2 detail page & see entries' do
#        url = '/reports/production_summary2?consortium=BaSH&type=GLT%20Mice&priority=High'
#        url2 = '/reports/production_summary2?consortium=BaSH&type=GLT%20Mice&priority=High'
#        
#        visit url
#        assert_match url2, current_url
#  
#        assert_match 'Production Summary Detail 2', page.body
#        assert_match 'Download as CSV', page.body
#        
#        #column_name = [
#        #  'Consortium',
#        #  'Sub-Project',
#        #  'Priority',
#        #  'Production Centre',
#        #  'Gene',
#        #  'Status',
#        #  'Assigned Date',
#        #  'Assigned - ES Cell QC In Progress Date',
#        #  'Assigned - ES Cell QC Complete Date',
#        #  'Micro-injection in progress Date',
#        #  'Genotype confirmed Date',
#        #  'Micro-injection aborted Date'
#        #]
#
#        counter = 1
#        COLUMN_NAMES_SUMMARY_DETAIL_PAGE_2.each do |name|
#          assert page.has_css?("div.report tr:nth-child(1) th:nth-child(#{counter})", :text => COLUMN_NAMES_SUMMARY_DETAIL_PAGE_2[counter-1])
#          counter += 1
#        end
#      end
#      
#      should 'allow users to visit the prod summary 2 page & see entries & check clickability of cell' do
#        visit '/reports/production_summary2'
#        assert_match '/reports/production_summary2', current_url
#
#        assert_match 'Production Summary 2', page.body
#        assert_match 'Download as CSV', page.body
#        
#        click_link 'bash_all_low'
#        assert_match '/reports/production_summary2?consortium=BaSH&type=All&priority=Low', current_url
#
#        save_and_open_page if DEBUG
#        
#        counter = 1
#        COLUMN_NAMES_SUMMARY_DETAIL_PAGE_2.each do |name|
#          assert page.has_css?("div.report tr:nth-child(1) th:nth-child(#{counter})", :text => COLUMN_NAMES_SUMMARY_DETAIL_PAGE_2[counter-1])
#          counter += 1
#        end
#      end
#      
#    end
#
#  end

end
