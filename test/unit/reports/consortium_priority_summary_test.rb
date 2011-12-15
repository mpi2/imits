# encoding: utf-8

require 'test_helper'

class Reports::ConsortiumPrioritySummaryTest < ActiveSupport::TestCase

  extend Reports::Helper
  include Reports::Helper
  
  DEBUG = false

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

  context 'Reports::ConsortiumPrioritySummary' do

    setup do
      assert ! ReportCache.find_by_name('mi_production_detail')
      ReportCache.create!(
        :name => 'mi_production_detail',
        :csv_data => TEST_CSV
      )
      assert ReportCache.find_by_name('mi_production_detail')
      
      report = get_cached_report('mi_production_detail')
      
      puts report.to_s if DEBUG
    
    end

    should 'do feed generate' do
      title2, report = Reports::ConsortiumPrioritySummary.generate1()
      
      #      puts title2
      puts report.to_s if DEBUG
      
      assert_equal 1, report.size
      
      column_names = [ 'Consortium', 'All', 'Activity', 'Mice in production', 'GLT Mice' ]

      assert_equal column_names, report.column_names

      expecteds = {
        'Consortium' => 'BaSH',
        'All' => "<a title='Click to see list of All' href='?consortium=BaSH&type=All'>10</a>",
        'Activity' => "<a title='Click to see list of Activity' href='?consortium=BaSH&type=Activity'>4</a>",
        'Mice in production' => "<a title='Click to see list of Mice in production' href='?consortium=BaSH&type=Mice+in+production'>2</a>",
        'GLT Mice' => "<a title='Click to see list of GLT Mice' href='?consortium=BaSH&type=GLT+Mice'>1</a>"
      }
      expecteds2 = {
        'Consortium' => 'BaSH',
        'All' => '10',
        'Activity' => '4',
        'Mice in production' => '2',
        'GLT Mice' => '1'
      }
      
      report.column_names.each do |column_name|
        puts "#{column_name}: " + report.column(column_name)[0] if DEBUG
        assert_equal expecteds[column_name], report.column(column_name)[0]
        next if column_name == 'Consortium'
        value = report.column(column_name)[0].scan( /\>(\d+)\</ ).last.first
        assert_equal expecteds2[column_name], value
      end
    
      #Consortium: BaSH
      #All:
      #Activity:
      #Mice in production:
      #GLT Mice:
      
      #      assert_equal 'BaSH', report.column('Consortium')[0]
    end

    should 'do feed generate detail' do
      #consortium=BaSH&type=Activity'
      title2, report = Reports::ConsortiumPrioritySummary.subsummary1({ :consortium => 'BaSH', :type => 'All' })
      puts report.to_s if DEBUG
      assert_equal 10, report.size
      title2, report = Reports::ConsortiumPrioritySummary.subsummary1({ :consortium => 'BaSH', :type => 'Activity' })
      puts report.to_s if DEBUG
      assert_equal 4, report.size
      title2, report = Reports::ConsortiumPrioritySummary.subsummary1({ :consortium => 'BaSH', :type => 'Mice in production' })
      puts report.to_s if DEBUG
      assert_equal 2, report.size
      title2, report = Reports::ConsortiumPrioritySummary.subsummary1({ :consortium => 'BaSH', :type => 'GLT Mice' })
      puts report.to_s if DEBUG
      assert_equal 1, report.size
    end

    should 'do summary generate 2' do
      title2, report = Reports::ConsortiumPrioritySummary.generate2()
      puts title2 if DEBUG
      puts report.to_s if DEBUG

      #report.column_names.each do |column_name|
      #  puts "#{column_name}: " + report.column(column_name)[0].to_s if DEBUG
      #end
      
      #puts "DATA: " + report.data.inspect
      #puts "DATA 2: " + report.data[0].inspect
      #puts "DATA 3: " + report.data[0].attributes.inspect
      #puts "DATA 4: " + report.data[0].data.inspect

      #      puts "DATA 2: " + report.data[2].data.inspect

      #Consortium: BaSH
      #Priority: Low
      #All: <a title='Click to see list of All' href='?consortium=BaSH&type=All&priority=Low'>1</a>
      #ES QC started:
      #ES QC finished:
      #MI in progress:
      #Aborted: <a title='Click to see list of Aborted' href='?consortium=BaSH&type=Aborted&priority=Low'>1</a>
      #GLT Mice:
      #Pipeline efficiency (%): 0

      #expecteds99 = {
      #  'BaSH' => {
      #    'Low' => {
      #      'All' => 1, 'ES QC started' => '', 'ES QC finished' => '', 'MI in progress' => '', 'Aborted' => '1', 'GLT Mice' => '', 'Pipeline efficiency (%)' =>''
      #    }
      #  }
      #}
      
      expected = [{"Consortium"=>"BaSH", "Priority"=>"Low",
          "All"=>"<a title='Click to see list of All' href='?consortium=BaSH&type=All&priority=Low'>1</a>",
          "ES QC started"=>"", "ES QC finished"=>"", "MI in progress"=>"",
          "Aborted"=>"<a title='Click to see list of Aborted' href='?consortium=BaSH&type=Aborted&priority=Low'>1</a>",
          "GLT Mice"=>"", "Pipeline efficiency (%)"=>0},
        {"Consortium"=>"BaSH", "Priority"=>"Medium", "All"=>"<a title='Click to see list of All' href='?consortium=BaSH&type=All&priority=Medium'>1</a>",
          "ES QC started"=>"", "ES QC finished"=>"", "MI in progress"=>"", "Aborted"=>"", "GLT Mice"=>"", "Pipeline efficiency (%)"=>0},
        {"Consortium"=>"BaSH", "Priority"=>"High", "All"=>"<a title='Click to see list of All' href='?consortium=BaSH&type=All&priority=High'>11</a>",
          "ES QC started"=>"<a title='Click to see list of ES QC started' href='?consortium=BaSH&type=ES QC started&priority=High'>1</a>",
          "ES QC finished"=>"<a title='Click to see list of ES QC finished' href='?consortium=BaSH&type=ES QC finished&priority=High'>1</a>",
          "MI in progress"=>"<a title='Click to see list of MI in progress' href='?consortium=BaSH&type=MI in progress&priority=High'>1</a>",
          "Aborted"=>"", "GLT Mice"=>"<a title='Click to see list of GLT Mice' href='?consortium=BaSH&type=GLT Mice&priority=High'>1</a>",
          "Pipeline efficiency (%)"=>"100.00"}
      ]

      assert_equal expected[0], report.data[0].data
      assert_equal expected[1], report.data[1].data
      assert_equal expected[2], report.data[2].data
      
    end

    should 'do summary 2 generate detail' do
      title2, report = Reports::ConsortiumPrioritySummary.subsummary2({ :consortium => 'BaSH', :type => 'All', :priority => 'Low' })
      puts report.to_s if DEBUG
      assert_equal 1, report.size
      title2, report = Reports::ConsortiumPrioritySummary.subsummary2({ :consortium => 'BaSH', :type => 'Aborted', :priority => 'Low' })
      puts report.to_s if DEBUG
      assert_equal 1, report.size
      title2, report = Reports::ConsortiumPrioritySummary.subsummary2({ :consortium => 'BaSH', :type => 'All', :priority => 'Medium' })
      puts report.to_s if DEBUG
      assert_equal 1, report.size
      title2, report = Reports::ConsortiumPrioritySummary.subsummary2({ :consortium => 'BaSH', :type => 'GLT Mice', :priority => 'High' })
      puts report.to_s if DEBUG
      assert_equal 1, report.size
      title2, report = Reports::ConsortiumPrioritySummary.subsummary2({ :consortium => 'BaSH', :type => 'ES QC finished', :priority => 'High' })
      puts report.to_s if DEBUG
      assert_equal 1, report.size
    end

    #should 'get table' do
    #
    #  gene_cbx1 = Factory.create :gene_cbx1
    #
    #  Factory.create :wtsi_mi_attempt_genotype_confirmed,
    #    :es_cell => Factory.create(:es_cell, :gene => gene_cbx1),
    #    :consortium_name => 'MGP',
    #    :is_active => true,
    #    :is_suitable_for_emma => true,
    #    :total_pups_born => 10,
    #    :total_male_chimeras => 10
    # 
    #  report = Reports::MonthlyProduction.generate()
    #  
    #  assert !report.blank?
    #  
    #  assert_equal 'MGP', report.column('Consortium')[0]
    #  assert_equal 'WTSI', report.column('Production Centre')[0]
    #  assert_equal 1, report.column('# Clones Injected')[0]
    #  assert_equal 1, report.column('# at Birth')[0]
    #  assert_equal 100, report.column('% at Birth')[0]
    #  assert_equal 1, report.column('# at Weaning')[0]
    #  assert_equal 1, report.column('# Genotype Confirmed')[0]
    #  assert_equal 100, report.column('% Genotype Confirmed')[0]
    #
    #end

  end

end
