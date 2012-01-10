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

  TEST_CSV2 = <<-"CSV"
"Consortium","Sub-Project","Priority","Production Centre","Gene","MGI Accession ID","Overall Status","MiPlan Status","MiAttempt Status","PhenotypeAttempt Status","IKMC Project ID","Mutation Sub-Type","Allele Symbol","Genetic Background","Assigned Date","Assigned - ES Cell QC In Progress Date","Assigned - ES Cell QC Complete Date","Micro-injection in progress Date","Genotype confirmed Date","Micro-injection aborted Date","Phenotype Attempt Registered Date","Rederivation Started Date","Rederivation Complete Date","Cre Excision Started Date","Cre Excision Complete Date","Phenotyping Started Date","Phenotyping Complete Date","Phenotype Attempt Aborted Date"
"BaSH",,"High",,"Eaf1","MGI:1921677","Interest","Interest",,,,,,,,,,,,,,,,,,,,
"BaSH",,"High",,"Grm6","MGI:1351343","Inspect - MI Attempt","Inspect - MI Attempt",,,,,,,,,,,,,,,,,,,,
"BaSH",,"High",,"Il17rb","MGI:1355292","Interest","Interest",,,,,,,,,,,,,,,,,,,,
"BaSH",,"High",,"Katnal1","MGI:2387638","Interest","Interest",,,,,,,,,,,,,,,,,,,,
"BaSH",,"High",,"Leprot","MGI:2687005","Interest","Interest",,,,,,,,,,,,,,,,,,,,
"BaSH",,"High",,"Mboat7","MGI:1924832","Interest","Interest",,,,,,,,,,,,,,,,,,,,
"BaSH",,"High",,"Mlxipl","MGI:1927999","Interest","Interest",,,,,,,,,,,,,,,,,,,,
"BaSH",,"High",,"Mthfd2l","MGI:1915871","Interest","Interest",,,,,,,,,,,,,,,,,,,,
"BaSH",,"High",,"Nbr1","MGI:108498","Interest","Interest",,,,,,,,,,,,,,,,,,,,
"BaSH",,"High",,"Nkx2-6","MGI:97351","Interest","Interest",,,,,,,,,,,,,,,,,,,,
"BaSH",,"High",,"Nlrc4","MGI:3036243","Interest","Interest",,,,,,,,,,,,,,,,,,,,
"BaSH",,"High",,"Ntrk1","MGI:97383","Interest","Interest",,,,,,,,,,,,,,,,,,,,
"BaSH",,"High",,"Pink1","MGI:1916193","Interest","Interest",,,,,,,,,,,,,,,,,,,,
"BaSH",,"High",,"Rab26","MGI:2443284","Interest","Interest",,,,,,,,,,,,,,,,,,,,
"BaSH",,"High",,"Rexo2","MGI:1888981","Interest","Interest",,,,,,,,,,,,,,,,,,,,
"BaSH",,"High",,"Sec24b","MGI:2139764","Interest","Interest",,,,,,,,,,,,,,,,,,,,
"BaSH",,"High",,"Stard10","MGI:1860093","Interest","Interest",,,,,,,,,,,,,,,,,,,,
"BaSH",,"High",,"Synpo2","MGI:2153070","Interest","Interest",,,,,,,,,,,,,,,,,,,,
  CSV

#    cached_report = ReportCache.find_by_name!('mi_production_intermediate').to_table


  context 'Reports::MiProduction::FeedImpc' do

    setup do
      assert ! ReportCache.find_by_name('mi_production_intermediate')
      ReportCache.create!(
        :name => 'mi_production_intermediate',
        :csv_data => TEST_CSV
      )
      assert ReportCache.find_by_name('mi_production_intermediate')      
      #report = get_cached_report('mi_production_intermediate')
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




#  context 'Reports::ConsortiumPrioritySummary' do
#
#    setup do
#      assert ! ReportCache.find_by_name('mi_production_detail')
#      ReportCache.create!(
#        :name => 'mi_production_detail',
#        :csv_data => TEST_CSV
#      )
#      assert ReportCache.find_by_name('mi_production_detail')      
#      report = get_cached_report('mi_production_detail')
#      puts report.to_s if DEBUG
#      assert report
#    end
#
#    should 'do feed generate' do
#      title2, report = Reports::ConsortiumPrioritySummary.generate1()
#      
#      puts report.to_s if DEBUG
#      
#      assert_equal 1, report.size
#      
#      column_names = [ 'Consortium', 'All', 'Activity', 'Mice in production', 'GLT Mice' ]
#
#      assert_equal column_names, report.column_names
#
#      expecteds = {
#        'Consortium' => 'BaSH',
#        'All' => "<a title='Click to see list of All' href='?consortium=BaSH&type=All'>10</a>",
#        'Activity' => "<a title='Click to see list of Activity' href='?consortium=BaSH&type=Activity'>4</a>",
#        'Mice in production' => "<a title='Click to see list of Mice in production' href='?consortium=BaSH&type=Mice+in+production'>2</a>",
#        'GLT Mice' => "<a title='Click to see list of GLT Mice' href='?consortium=BaSH&type=GLT+Mice'>1</a>"
#      }
#      expecteds2 = {
#        'Consortium' => 'BaSH',
#        'All' => '10',
#        'Activity' => '4',
#        'Mice in production' => '2',
#        'GLT Mice' => '1'
#      }
#      
#      report.column_names.each do |column_name|
#        puts "#{column_name}: " + report.column(column_name)[0] if DEBUG
#        assert_equal expecteds[column_name], report.column(column_name)[0]
#        next if column_name == 'Consortium'
#        value = report.column(column_name)[0].scan( /\>(\d+)\</ ).last.first
#        assert_equal expecteds2[column_name], value
#      end
#
#    end
#
#    should 'do feed generate detail' do
#      title2, report = Reports::MiProduction::FeedImpc.subsummary({ :consortium => 'BaSH', :type => 'All' })
#      puts report.to_s if DEBUG
#      assert_equal 10, report.size
#      title2, report = Reports::MiProduction::FeedImpc.subsummary({ :consortium => 'BaSH', :type => 'Activity' })
#      puts report.to_s if DEBUG
#      assert_equal 4, report.size
#      title2, report = Reports::MiProduction::FeedImpc.subsummary({ :consortium => 'BaSH', :type => 'Mice in production' })
#      puts report.to_s if DEBUG
#      assert_equal 2, report.size
#      title2, report = Reports::MiProduction::FeedImpc.subsummary({ :consortium => 'BaSH', :type => 'GLT Mice' })
#      puts report.to_s if DEBUG
#      assert_equal 1, report.size
#    end
#
#    should 'do summary generate 2' do
#      title2, report = Reports::ConsortiumPrioritySummary.generate2()
#      puts title2 if DEBUG
#      puts report.to_s if DEBUG
#      
#      expected = [
#        {"Aborted"=>
#            "<a title='Click to see list of Aborted' id='bash_aborted_low' href='?consortium=BaSH&type=Aborted&priority=Low'>1</a>",
#          "All"=> "<a title='Click to see list of All' id='bash_all_low' href='?consortium=BaSH&type=All&priority=Low'>1</a>",
#          "Consortium"=>"BaSH",
#          "ES QC finished"=>"",
#          "ES QC started"=>"",
#          "GLT Mice"=>"",
#          "MI in progress"=>"",
#          "Pipeline efficiency (%)"=>0,
#          "Priority"=>"Low"},
#        {"Aborted"=>"",
#          "All"=> "<a title='Click to see list of All' id='bash_all_medium' href='?consortium=BaSH&type=All&priority=Medium'>1</a>",
#          "Consortium"=>"BaSH",
#          "ES QC finished"=>"",
#          "ES QC started"=>"",
#          "GLT Mice"=>"",
#          "MI in progress"=>"",
#          "Pipeline efficiency (%)"=>0,
#          "Priority"=>"Medium"},
#        {"Aborted"=>"",
#          "All"=>
#            "<a title='Click to see list of All' id='bash_all_high' href='?consortium=BaSH&type=All&priority=High'>11</a>",
#          "Consortium"=>"BaSH",
#          "ES QC finished"=>
#            "<a title='Click to see list of ES QC finished' id='bash_es_qc_finished_high' href='?consortium=BaSH&type=ES QC finished&priority=High'>1</a>",
#          "ES QC started"=>
#            "<a title='Click to see list of ES QC started' id='bash_es_qc_started_high' href='?consortium=BaSH&type=ES QC started&priority=High'>1</a>",
#          "GLT Mice"=>
#            "<a title='Click to see list of GLT Mice' id='bash_glt_mice_high' href='?consortium=BaSH&type=GLT Mice&priority=High'>1</a>",
#          "MI in progress"=>
#            "<a title='Click to see list of MI in progress' id='bash_mi_in_progress_high' href='?consortium=BaSH&type=MI in progress&priority=High'>1</a>",
#          "Pipeline efficiency (%)"=>"100.00",
#          "Priority"=>"High"}
#      ]
#
#      assert_equal expected[0], report.data[0].data
#      assert_equal expected[1], report.data[1].data
#      assert_equal expected[2], report.data[2].data
#      
#    end
#
#    should 'do summary 2 generate detail' do
#      title2, report = Reports::ConsortiumPrioritySummary.subsummary2({ :consortium => 'BaSH', :type => 'All', :priority => 'Low' })
#      puts report.to_s if DEBUG
#      assert_equal 1, report.size
#      title2, report = Reports::ConsortiumPrioritySummary.subsummary2({ :consortium => 'BaSH', :type => 'Aborted', :priority => 'Low' })
#      puts report.to_s if DEBUG
#      assert_equal 1, report.size
#      title2, report = Reports::ConsortiumPrioritySummary.subsummary2({ :consortium => 'BaSH', :type => 'All', :priority => 'Medium' })
#      puts report.to_s if DEBUG
#      assert_equal 1, report.size
#      title2, report = Reports::ConsortiumPrioritySummary.subsummary2({ :consortium => 'BaSH', :type => 'GLT Mice', :priority => 'High' })
#      puts report.to_s if DEBUG
#      assert_equal 1, report.size
#      title2, report = Reports::ConsortiumPrioritySummary.subsummary2({ :consortium => 'BaSH', :type => 'ES QC finished', :priority => 'High' })
#      puts report.to_s if DEBUG
#      assert_equal 1, report.size
#    end
#
#  end
#
  end

end
