# encoding: utf-8

require 'test_helper'

class Reports::MiProduction::FeedImpcTest <
    #Kermits2::JsIntegrationTest
  ActionDispatch::IntegrationTest

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
      
      #  save_and_open_page if DEBUG
    
      sleep(10.seconds) if DEBUG

    end    
  
    should 'allow users to visit the feed demo detail page & see entries - just table (without login)' do
      visit '/reports/mi_production/summary_by_consortium_and_accumulated_status&feed=true'
      assert_match '/reports/mi_production/summary_by_consortium_and_accumulated_status&feed=true', current_url

      #assert_match 'Production Summary 1 (feed)', page.body
      #assert_match 'Download as CSV', page.body

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
  
      #assert_match 'Production Summary 1 Detail (feed)', page.body
      #assert_match 'Download as CSV', page.body
      #assert_match 'ikmc-favicon.ico', page.body      
      
      # save_and_open_page if DEBUG
    
      sleep(10.seconds) if DEBUG
    end
    
  end

end
