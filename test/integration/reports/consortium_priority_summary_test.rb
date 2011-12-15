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
      
      #      puts report.to_s if DEBUG
    
    end

    should 'allow users to visit the feed demo page & see entries (without login)' do
      visit '/reports/production_summary1'
      assert_match '/reports/production_summary1', current_url

      #save_and_open_page if DEBUG

      assert_match 'Production Summary 1 (feed)', page.body

      #Consortium 	All 	Activity 	Mice in production 	GLT Mice
      #BaSH 	10 	4 	2 	1

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

      #      puts "LENGTH1: " + page.body.length.to_s
      #      puts "STRING1: " + page.body
    end
    
    # gives just table using curl http://localhost:3000/reports/production_summary1?feed=true
    
    should 'allow users to visit the feed demo detail page & see entries (without login)' do
      visit '/reports/production_summary1?consortium=BaSH&type=Mice+in+production'
      save_and_open_page if DEBUG
      assert_match '/reports/production_summary1?consortium=BaSH&type=Mice%20in%20production', current_url
      #http://www.example.com/reports/production_summary1?consortium=BaSH&type=Mice%20in%20production


      column_name = ['Consortium', 'Sub-Project', 'Priority', 'Production Centre', 'Gene', 'Status', 'Assigned Date',
                     'Assigned - ES Cell QC In Progress Date', 'Assigned - ES Cell QC Complete Date', 'Micro-injection in progress Date',
                     'Genotype confirmed Date', 'Micro-injection aborted Date']
      
      counter = 1
      column_name.each do |name|
        assert page.has_css?("div.report tr:nth-child(1) th:nth-child(#{counter})", :text => column_name[counter-1])
        counter += 1
      end

      #assert page.has_css?('div.report tr:nth-child(1) th:nth-child(1)', :text => column_name[0])
      #assert page.has_css?('div.report tr:nth-child(1) th:nth-child(2)', :text => column_name[1])
      #assert page.has_css?('div.report tr:nth-child(1) th:nth-child(3)', :text => column_name[2])
      #assert page.has_css?('div.report tr:nth-child(1) th:nth-child(4)', :text => column_name[3])
      #assert page.has_css?('div.report tr:nth-child(1) th:nth-child(5)', :text => column_name[4])
      #assert page.has_css?('div.report tr:nth-child(1) th:nth-child(6)', :text => column_name[5])
      #assert page.has_css?('div.report tr:nth-child(1) th:nth-child(7)', :text => column_name[6])
      #assert page.has_css?('div.report tr:nth-child(1) th:nth-child(8)', :text => column_name[7])
      #assert page.has_css?('div.report tr:nth-child(1) th:nth-child(9)', :text => column_name[8])
      #assert page.has_css?('div.report tr:nth-child(1) th:nth-child(10)', :text => column_name[9])
      #assert page.has_css?('div.report tr:nth-child(1) th:nth-child(11)', :text => column_name[10])
      #assert page.has_css?('div.report tr:nth-child(1) th:nth-child(12)', :text => column_name[11])

      column_name = ['BaSH', '', 'High', 'BCM', 'Prdm14', 'Genotype confirmed', '2011-10-10', '2011-11-22', '', '2011-12-02', '2011-12-02', '']

      counter = 1
      column_name.each do |name|
#        puts "expected: #{column_name[counter-1]}"
        assert page.has_css?("div.report tr:nth-child(2) td:nth-child(#{counter})", :text => column_name[counter-1])
        counter += 1
      end

      #BaSH 	  	High 	BCM 	Alg10b 	Micro-injection in progress 	2011-10-10 	  	  	2011-09-08
    end

    should 'allow users to visit the feed demo url & see text (without login)' do
      visit '/reports/production_summary1?feed=true'
      assert_match '/reports/production_summary1?feed=true', current_url

      #      save_and_open_page if DEBUG
      
      #      puts "LENGTH2: " + page.body.length.to_s
      #      puts "STRING2: " + page.body
      
      assert page.body.length > 0
    end
    
    should 'allow users to visit the feed demo detail url & see text (without login)'

    context 'once logged in' do
      setup do
        create_common_test_objects
        visit '/users/logout'
        login
      end

      should 'allow users to visit the prod summary 2 page & see entries'
      
      #should 'allow users to visit the feed demo page & see entries' do
      #
      #  gene_cbx1 = Factory.create :gene_cbx1
      #
      #  Factory.create :mi_plan, :gene => gene_cbx1,
      #    :consortium => Consortium.find_by_name('BaSH'),
      #    :production_centre => Centre.find_by_name('WTSI'),
      #    :mi_plan_status => MiPlanStatus['Assigned']
      #
      #  Factory.create :mi_plan, :gene => gene_cbx1,
      #    :consortium => Consortium.find_by_name('JAX'),
      #    :production_centre => Centre.find_by_name('JAX'),
      #    :number_of_es_cells_starting_qc => 5
      #
      #  visit '/reports/double_assigned_plans'
      #  assert_match '/reports/double_assigned_plans', current_url
      #
      #  assert page.has_css?('div#double-matrix tr:nth-child(2) td:nth-child(4)', :text => '1')
      #  assert page.has_css?('a', :text => 'Download Matrix as CSV')
      #
      #  assert_match 'Double-Assignments for Consortium: BaSH', page.body
      #  assert_match 'Double-Assignments for Consortium: JAX', page.body
      #
      #  assert page.has_content? "Marker Symbol Consortium Plan Status MI Status Centre MI Date"
      #  assert page.has_content? "Cbx1 BaSH Assigned"
      #
      #  assert page.has_css?('a', :text => 'Download List as CSV')
      #
      #  assert_equal 3, all('table').count
      #
      #end
      #
    end

  end
end
