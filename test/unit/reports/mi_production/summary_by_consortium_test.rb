# encoding: utf-8

require 'test_helper'

class Reports::MiProduction::SummaryByConsortiumTest < ActiveSupport::TestCase

  #extend Reports::Helper
  #include Reports::Helper
  include Reports::MiProduction::SummariesCommon
  
  DEBUG = false

#  TEST_CSV = <<-"CSV"
#"Consortium","Sub-Project","Priority","Production Centre","Gene","MGI Accession ID","Overall Status","MiPlan Status","MiAttempt Status","PhenotypeAttempt Status","IKMC Project ID","Mutation Sub-Type","Allele Symbol","Genetic Background","Assigned Date","Assigned - ES Cell QC In Progress Date","Assigned - ES Cell QC Complete Date","Micro-injection in progress Date","Genotype confirmed Date","Micro-injection aborted Date","Phenotype Attempt Registered Date","Rederivation Started Date","Rederivation Complete Date","Cre Excision Started Date","Cre Excision Complete Date","Phenotyping Started Date","Phenotyping Complete Date","Phenotype Attempt Aborted Date"
#"BaSH",,"High","BCM","1700093J21Rik","MGI:1921546","Assigned - ES Cell QC In Progress","Assigned - ES Cell QC In Progress",,,,,,,"2011-10-10","2011-11-16",,,,,,,,,,,,
#"BaSH",,"High","BCM","Akt1s1","MGI:1914855","Micro-injection in progress","Assigned","Micro-injection in progress",,28913,"conditional_ready","Akt1s1<sup>tm1a(EUCOMM)Wtsi</sup>","C57BL/6N","2011-10-10",,,"2011-09-27",,,,,,,,,,
#"BaSH",,"High","BCM","Alg10b","MGI:2146159","Genotype confirmed","Assigned","Genotype confirmed",,"VG10825","deletion","Alg10b<sup>tm1(KOMP)Vlcg</sup>","C57BL/6N","2011-10-10",,,"2011-09-08","2012-01-07",,,,,,,,,
#"BaSH",,"High","BCM","Acot6","MGI:1921287","Phenotyping Complete","Assigned","Genotype confirmed","Phenotyping Complete",31219,"conditional_ready","Acot6<sup>tm1a(KOMP)Wtsi</sup>","C57BL/6NTac/Den","2008-06-11",,,"2008-06-11","2008-12-29",,"2012-01-09",,,"2012-01-09",,"2012-01-09","2012-01-09",
#"BaSH",,"High","BCM","Adsl","MGI:103202","Assigned - ES Cell QC Complete","Assigned - ES Cell QC Complete",,,,,,,"2011-10-10","2011-11-04","2011-11-25"
#"BaSH",,"High","BCM","Clvs2","MGI:2443223","Aborted - ES Cell QC Failed","Aborted - ES Cell QC Failed",,,,,,,"2011-10-10"
#"BaSH",,"High","BCM","Apc2","MGI:1346052","Micro-injection aborted","Assigned","Micro-injection aborted",,26234,"conditional_ready","Apc2<sup>tm1a(KOMP)Wtsi</sup>",,"2011-12-01",,,"2011-09-05",,"2011-12-02"
#"BaSH",,"High","BCM","Akt1s1","MGI:1914855","Micro-injection in progress","Assigned","Micro-injection in progress",,28913,"conditional_ready","Akt1s1<sup>tm1a(EUCOMM)Wtsi</sup>","C57BL/6N","2011-10-10",,,"2009-09-27"
#  CSV
#
#  TEST_CSV2 = <<-"CSV"
#"Consortium","Sub-Project","Priority","Production Centre","Gene","MGI Accession ID","Overall Status","MiPlan Status","MiAttempt Status","PhenotypeAttempt Status","IKMC Project ID","Mutation Sub-Type","Allele Symbol","Genetic Background","Assigned Date","Assigned - ES Cell QC In Progress Date","Assigned - ES Cell QC Complete Date","Micro-injection in progress Date","Genotype confirmed Date","Micro-injection aborted Date","Phenotype Attempt Registered Date","Rederivation Started Date","Rederivation Complete Date","Cre Excision Started Date","Cre Excision Complete Date","Phenotyping Started Date","Phenotyping Complete Date","Phenotype Attempt Aborted Date"
#"BaSH",,"High","BCM","1700093J21Rik","MGI:1921546","Assigned - ES Cell QC In Progress","Assigned - ES Cell QC In Progress",,,,,,,"2011-10-10","2011-11-16",,,,,,,,,,,,
#  CSV

  expecteds = {
      'All' => 7,
      'ES QC started' => 1,
      'ES QC confirmed' => 1,
      'ES QC failed' => 1,
      'MI in progress' => 2,
      'MI Aborted' => 1,
      'Genotype Confirmed Mice' => 1,
      'Pipeline efficiency (%)' => 33
    }

  HEADING = '"Consortium","Sub-Project","Priority","Production Centre","Gene","MGI Accession ID","Overall Status","MiPlan Status","MiAttempt Status","PhenotypeAttempt Status","IKMC Project ID","Mutation Sub-Type","Allele Symbol","Genetic Background","Assigned Date","Assigned - ES Cell QC In Progress Date","Assigned - ES Cell QC Complete Date","Micro-injection in progress Date","Genotype confirmed Date","Micro-injection aborted Date","Phenotype Attempt Registered Date","Rederivation Started Date","Rederivation Complete Date","Cre Excision Started Date","Cre Excision Complete Date","Phenotyping Started Date","Phenotyping Complete Date","Phenotype Attempt Aborted Date"'
  ES_QC_STARTED  = '"BaSH",,"High","BCM","1700093J21Rik","MGI:1921546","Assigned - ES Cell QC In Progress","Assigned - ES Cell QC In Progress",,,,,,,"2011-10-10","2011-11-16",,,,,,,,,,,,'
  ES_QC_CONFIRMED  = '"BaSH",,"High","BCM","Adsl","MGI:103202","Assigned - ES Cell QC Complete","Assigned - ES Cell QC Complete",,,,,,,"2011-10-10","2011-11-04","2011-11-25"'
  ES_QC_FAILED = '"BaSH",,"High","BCM","Clvs2","MGI:2443223","Aborted - ES Cell QC Failed","Aborted - ES Cell QC Failed",,,,,,,"2011-10-10"'
  MI_IN_PROGRESS = '"BaSH",,"High","BCM","Akt1s1","MGI:1914855","Micro-injection in progress","Assigned","Micro-injection in progress",,28913,"conditional_ready","Akt1s1<sup>tm1a(EUCOMM)Wtsi</sup>","C57BL/6N","2011-10-10",,,"2011-09-27",,,,,,,,,,'
  MI_ABORTED = '"BaSH",,"High","BCM","Apc2","MGI:1346052","Micro-injection aborted","Assigned","Micro-injection aborted",,26234,"conditional_ready","Apc2<sup>tm1a(KOMP)Wtsi</sup>",,"2011-12-01",,,"2011-09-05",,"2011-12-02"'
  GENOTYPE_CONFIRMED_MICE = '"BaSH",,"High","BCM","Alg10b","MGI:2146159","Genotype confirmed","Assigned","Genotype confirmed",,"VG10825","deletion","Alg10b<sup>tm1(KOMP)Vlcg</sup>","C57BL/6N","2011-10-10",,,"2011-09-08","2012-01-07",,,,,,,,,'
  LANGUISHING = '"BaSH",,"High","BCM","Akt1s1","MGI:1914855","Micro-injection in progress","Assigned","Micro-injection in progress",,28913,"conditional_ready","Akt1s1<sup>tm1a(EUCOMM)Wtsi</sup>","C57BL/6N","2011-10-10",,,"2009-09-27"'
  
  def get_csv
    HEADING + "\n" +
    ES_QC_STARTED + "\n" +
    ES_QC_CONFIRMED + "\n" +
      ES_QC_FAILED + "\n" +
      MI_IN_PROGRESS + "\n" +
      MI_ABORTED + "\n" +
      GENOTYPE_CONFIRMED_MICE  + "\n" +
      LANGUISHING
  end

#+-------------------------------------------------------------------------------------------------------------------------------------------------------------------+
#| Consortium | All | ES QC started | ES QC confirmed | ES QC failed | MI in progress | MI Aborted | Genotype Confirmed Mice | Pipeline efficiency (%) | Languishing |
#+-------------------------------------------------------------------------------------------------------------------------------------------------------------------+
#| BaSH       | 8   | 1             | 1               | 1            | 2              | 1          | 1                       | 33                      | 1           |
#+-------------------------------------------------------------------------------------------------------------------------------------------------------------------+

  context 'Reports::MiProduction::SummaryByConsortium' do

    setup do
      assert ! ReportCache.find_by_name('mi_production_intermediate')
      ReportCache.create!(
        :name => 'mi_production_intermediate',
        :csv_data => get_csv
      )
      assert ReportCache.find_by_name('mi_production_intermediate')      
      report = ReportCache.find_by_name!('mi_production_intermediate').to_table
      
      puts 'SETUP:' if DEBUG
      puts report.to_s if DEBUG
      assert report
    end
    
    should 'do generate simple' do
      #template = "Consortium","Sub-Project","Priority","Production Centre","Gene","MGI Accession ID","Overall Status","MiPlan Status","MiAttempt Status","PhenotypeAttempt Status","IKMC Project ID","Mutation Sub-Type","Allele Symbol","Genetic Background","Assigned Date","Assigned - ES Cell QC In Progress Date","Assigned - ES Cell QC Complete Date","Micro-injection in progress Date","Genotype confirmed Date","Micro-injection aborted Date","Phenotype Attempt Registered Date","Rederivation Started Date","Rederivation Complete Date","Cre Excision Started Date","Cre Excision Complete Date","Phenotyping Started Date","Phenotyping Complete Date","Phenotype Attempt Aborted Date"
      template = "BaSH","Sub-Project","Priority","BCM","Gene","MGI Accession ID","Overall Status","MiPlan Status","MiAttempt Status","PhenotypeAttempt Status","IKMC Project ID","Mutation Sub-Type","Allele Symbol","Genetic Background","Assigned Date","Assigned - ES Cell QC In Progress Date","Assigned - ES Cell QC Complete Date","Micro-injection in progress Date","Genotype confirmed Date","Micro-injection aborted Date","Phenotype Attempt Registered Date","Rederivation Started Date","Rederivation Complete Date","Cre Excision Started Date","Cre Excision Complete Date","Phenotyping Started Date","Phenotyping Complete Date","Phenotype Attempt Aborted Date"
    end

    should 'do generate' do
      title2, report = Reports::MiProduction::SummaryByConsortium.generate(nil, {'debug'=>'true'}, nil)
      
      puts 'do generate: ' + title2 if DEBUG
      puts report.to_s if DEBUG

      puts "report size: #{report.size}" if DEBUG
      puts "report column_names:" + report.column_names.inspect if DEBUG
      
      report = de_tag_table(report)
      puts report.to_s if DEBUG
      
      assert_equal 1, report.size

#+-------------------------------------------------------------------------------------------------------------------------------------------------------------------+
#| Consortium | All | ES QC started | ES QC confirmed | ES QC failed | MI in progress | MI Aborted | Genotype Confirmed Mice | Pipeline efficiency (%) | Languishing |
#+-------------------------------------------------------------------------------------------------------------------------------------------------------------------+
#| BaSH       | 8   | 1             | 1               | 1            | 2              | 1          | 1                       | 33                      | 1           |
#+-------------------------------------------------------------------------------------------------------------------------------------------------------------------+

      #assert_equal 'BaSH', report.column('Consortium')[0]
      #assert_equal '7', report.column('All')[0]
      #assert_equal '1', report.column('ES QC started')[0]
      #assert_equal '1', report.column('ES QC confirmed')[0]
      #assert_equal '1', report.column('ES QC failed')[0]
      #assert_equal '2', report.column('MI in progress')[0]
      #assert_equal '1', report.column('MI Aborted')[0]
      #assert_equal '1', report.column('Genotype Confirmed Mice')[0]
      #assert_equal '33', report.column('Pipeline efficiency (%)')[0]  # Pipeline Efficiency= #GLT / #GLT + MI aborted + MI in progress (>6 months)
      #                                                                # which is 1 / (1 + 1 + 1)
      #assert_equal '1', report.column('Languishing')[0]

      # Pipeline Efficiency= #GLT / #GLT + MI aborted + MI in progress (>6 months)
      # which is 1 / (1 + 1 + 1)
      
        expecteds.each_pair do |k,v|
          puts "#{k} : #{v}" if DEBUG
          assert_equal v.to_s, report.column(k)[0]
        end
            
    end
    
    should 'do generate detail' do
      puts 'do generate detail:' if DEBUG
            
        expecteds.each_pair do |k,v|
          next if k == 'Pipeline efficiency (%)'
          puts "#{k} : #{v}" if DEBUG
          title2, report = Reports::MiProduction::SummaryByConsortium.subsummary_common(nil, { :consortium => 'BaSH', :type => k })
          puts "report size: #{report.size}" if DEBUG
          puts report.to_s if DEBUG
          assert_equal v, report.size
        end
      
    end

  end

end
