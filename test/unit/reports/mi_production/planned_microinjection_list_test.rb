# encoding: utf-8

require 'test_helper'

class Reports::MiProduction::PlannedMicroinjectionListTest < ActiveSupport::TestCase

  DEBUG = false

  context 'Reports::MiProduction::PlannedMicroinjectionList' do
    setup do
    end

    def bash; @consortium_bash ||= Consortium.find_by_name! 'BaSH'; end
    def wtsi; @centre_wtsi ||= Centre.find_by_name! 'WTSI'; end
    def cbx1; @gene_cbx1 ||= Factory.create :gene_cbx1; end

    should 'create BaSH report' do

      bash_plan1 = Factory.create :mi_plan,
              :consortium => bash,
              :status => MiPlan::Status['Assigned']
      assert_equal 'Assigned', bash_plan1.status.name

      report = Reports::MiProduction::PlannedMicroinjectionList.new 'BaSH'

      array = report.to_csv.lines.first 2

      puts "report: " + report.to_csv
      puts "0: " + array[0].to_s
      puts "1: " + array[1].to_s

      assert_match "Consortium,SubProject,Bespoke,Production Centre,Marker Symbol,MGI Accession ID,Priority,Status,Reason for Inspect/Conflict,Non-Assigned Plans,Assigned Plans,Aborted MIs,MIs in Progress,GLT Mice", array[0]
#      assert_match(/BaSH,\"\",No,,Auto-generated Symbol 1,MGI\:0000000001,High,Assigned,,,[BaSH],,,\n/, array[1])
      assert_match 'BaSH,"",No,,Auto-generated Symbol 1,MGI:0000000001,High,Assigned,,,[BaSH],,,', array[1]

    end
  end



  #DEBUG = false
  #
  #context 'Reports::MiProduction::FeedImpc' do
  #
  #  setup do
  #    assert ! ReportCache.find_by_name('mi_production_intermediate')
  #    Factory.create(:report_cache,
  #      :name => 'mi_production_intermediate',
  #      :data => ProductionSummaryHelper::get_csv('feed unit')
  #    )
  #    assert ReportCache.find_by_name('mi_production_intermediate')
  #    report = ReportCache.find_by_name!('mi_production_intermediate').to_table
  #
  #    puts 'SETUP:' if DEBUG
  #    puts report.to_s if DEBUG
  #    assert report
  #  end
  #
  #  should 'do feed generate' do
  #    title2, report = Reports::MiProduction::FeedImpc.generate()
  #
  #    puts 'do feed generate: ' + title2 if DEBUG
  #    puts report.to_s if DEBUG
  #
  #    puts "report size: #{report.size}" if DEBUG
  #    puts "report column_names:" + report.column_names.inspect if DEBUG
  #
  #    assert_equal 2, report.size
  #
  #    column_names = [ "Consortium", "All Projects", "Project started", "Microinjection in progress", "Genotype Confirmed Mice", "Phenotype data available" ]
  #
  #    assert_equal column_names, report.column_names
  #
  #    puts "report expecteds:" + report.inspect if DEBUG
  #
  #    expecteds1 = ProductionSummaryHelper::get_expecteds 'feed_unit_1'
  #    expecteds2 = ProductionSummaryHelper::get_expecteds 'feed_unit_2'
  #
  #    report.column_names.each do |column_name|
  #      puts "'#{column_name}' => \"" + report.column(column_name)[0] + '",' if DEBUG
  #      assert_equal expecteds1[column_name], report.column(column_name)[0]
  #      next if column_name == 'Consortium'
  #      value = report.column(column_name)[0].scan( /\>(\d+)\</ ).last.first
  #      assert_equal expecteds2[column_name], value
  #    end
  #
  #  end
  #
  #  should 'do feed generate detail' do
  #
  #    expecteds3 = ProductionSummaryHelper::get_expecteds 'feed_unit_3'
  #
  #    expecteds3.each do |item|
  #      title2, report = Reports::MiProduction::FeedImpc.subsummary(nil, { :consortium => item[:consortium], :type => item[:type] })
  #      puts report.to_s if DEBUG
  #      assert_equal item[:result], report.size
  #    end
  #
  #  end
  #
  #end

end
