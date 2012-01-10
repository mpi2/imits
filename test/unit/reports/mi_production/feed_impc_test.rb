# encoding: utf-8

require 'test_helper'

class Reports::MiProduction::FeedImpcTest < ActiveSupport::TestCase

  extend Reports::Helper
  include Reports::Helper
  
  DEBUG = false

  TEST_CSV = <<-"CSV"
"Consortium","Sub-Project","Priority","Production Centre","Gene","MGI Accession ID","Overall Status","MiPlan Status","MiAttempt Status","PhenotypeAttempt Status","IKMC Project ID","Mutation Sub-Type","Allele Symbol","Genetic Background","Assigned Date","Assigned - ES Cell QC In Progress Date","Assigned - ES Cell QC Complete Date","Micro-injection in progress Date","Genotype confirmed Date","Micro-injection aborted Date","Phenotype Attempt Registered Date","Rederivation Started Date","Rederivation Complete Date","Cre Excision Started Date","Cre Excision Complete Date","Phenotyping Started Date","Phenotyping Complete Date","Phenotype Attempt Aborted Date"
"BaSH",,"High","BCM","1700093J21Rik","MGI:1921546","Assigned - ES Cell QC In Progress","Assigned - ES Cell QC In Progress",,,,,,,"2011-10-10","2011-11-16",,,,,,,,,,,,
"BaSH",,"High","BCM","Akt1s1","MGI:1914855","Micro-injection in progress","Assigned","Micro-injection in progress",,28913,"conditional_ready","Akt1s1<sup>tm1a(EUCOMM)Wtsi</sup>","C57BL/6N","2011-10-10",,,"2011-09-27",,,,,,,,,,
"BaSH",,"High","BCM","Alg10b","MGI:2146159","Genotype confirmed","Assigned","Genotype confirmed",,"VG10825","deletion","Alg10b<sup>tm1(KOMP)Vlcg</sup>","C57BL/6N","2011-10-10",,,"2011-09-08","2012-01-07",,,,,,,,,
"BaSH",,"High","BCM","Acot6","MGI:1921287","Phenotyping Complete","Assigned","Genotype confirmed","Phenotyping Complete",31219,"conditional_ready","Acot6<sup>tm1a(KOMP)Wtsi</sup>","C57BL/6NTac/Den","2008-06-11",,,"2008-06-11","2008-12-29",,"2012-01-09",,,"2012-01-09",,"2012-01-09","2012-01-09",
  CSV

  context 'Reports::MiProduction::FeedImpc' do

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

    should 'do feed generate' do
      title2, report = Reports::MiProduction::FeedImpc.generate()
      
      puts 'do feed generate: ' + title2 if DEBUG
      puts report.to_s if DEBUG

      puts "report size: #{report.size}" if DEBUG
      puts "report column_names:" + report.column_names.inspect if DEBUG
      
      assert_equal 2, report.size
      
      column_names = [ "Consortium", "All Projects", "Project started", "Microinjection in progress", "Genotype Confirmed Mice", "Phenotype data available" ]
      
      assert_equal column_names, report.column_names

      puts "report expecteds:" + report.inspect if DEBUG

      expecteds = {
        'Consortium' => "BaSH",
        'All Projects' => "<a title='Click to see list of All Projects' href='?consortium=BaSH&type=All+Projects'>4</a>",
        'Project started' => "<a title='Click to see list of Project started' href='?consortium=BaSH&type=Project+started'>3</a>",
        'Microinjection in progress' => "<a title='Click to see list of Microinjection in progress' href='?consortium=BaSH&type=Microinjection+in+progress'>2</a>",
        'Genotype Confirmed Mice' => "<a title='Click to see list of Genotype Confirmed Mice' href='?consortium=BaSH&type=Genotype+Confirmed+Mice'>1</a>",
        'Phenotype data available' => "<a title='Click to see list of Phenotype data available' href='?consortium=BaSH&type=Phenotype+data+available'>1</a>"
      }
      
      expecteds2 = {
        'Consortium' => "BaSH",
        'All Projects' => "4",
        'Project started' => "3",
        'Microinjection in progress' => "2",
        'Genotype Confirmed Mice' => "1",
        'Phenotype data available' => "1"
      }
      
      report.column_names.each do |column_name|
        puts "'#{column_name}' => \"" + report.column(column_name)[0] + '",' if DEBUG
        assert_equal expecteds[column_name], report.column(column_name)[0]
        next if column_name == 'Consortium'
        value = report.column(column_name)[0].scan( /\>(\d+)\</ ).last.first
        assert_equal expecteds2[column_name], value
      end
      
    end
    
    should 'do feed generate detail' do
      title2, report = Reports::MiProduction::FeedImpc.subsummary(nil, { :consortium => 'BaSH', :type => 'All Projects' })
      puts report.to_s if DEBUG
      assert_equal 4, report.size
      title2, report = Reports::MiProduction::FeedImpc.subsummary(nil, { :consortium => 'BaSH', :type => 'Project started' })
      puts report.to_s if DEBUG
      assert_equal 3, report.size
      title2, report = Reports::MiProduction::FeedImpc.subsummary(nil, { :consortium => 'BaSH', :type => 'Microinjection in progress' })
      puts report.to_s if DEBUG
      assert_equal 2, report.size
      title2, report = Reports::MiProduction::FeedImpc.subsummary(nil, { :consortium => 'BaSH', :type => 'Genotype Confirmed Mice' })
      puts report.to_s if DEBUG
      assert_equal 1, report.size
      title2, report = Reports::MiProduction::FeedImpc.subsummary(nil, { :consortium => 'BaSH', :type => 'Phenotype data available' })
      puts report.to_s if DEBUG
      assert_equal 1, report.size
    end

  end

end
