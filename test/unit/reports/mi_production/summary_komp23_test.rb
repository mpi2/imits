# encoding: utf-8

require 'test_helper'

class Reports::MiProduction::SummaryKomp23Test < ActiveSupport::TestCase

  DEBUG = false
  
  context 'Reports::MiProduction::SummaryKomp23' do

    setup do
      assert ! ReportCache.find_by_name('mi_production_intermediate')
      data = ProductionSummaryHelper::get_csv('komp23')
      assert data
      ReportCache.create!(
        :name => 'mi_production_intermediate',
        :csv_data => data
      )
      assert ReportCache.find_by_name('mi_production_intermediate')      
      report = ReportCache.find_by_name!('mi_production_intermediate').to_table
      
      puts 'SETUP:' if DEBUG
      puts report.to_s if DEBUG
      assert report
    end
    
    should 'do generate' do
      title2, report = Reports::MiProduction::SummaryKomp23.generate(nil, {'table' => 'true'}, false)
      
      puts 'do generate: ' + title2 if DEBUG
      puts report.to_s if DEBUG
      puts report.data.inspect if DEBUG

      expected = {
        "Consortium"=>"BaSH",
        "All Genes"=>11,
        "ES QCs"=>3,
        "ES QC confirms"=>2,
        "ES QC Failures"=>1,
        "Production Centre"=>"BCM",
        "MIs"=>10,
        "Chimaeras"=>nil,
        "Genotype Confirmed"=>1,
        "MI Aborted"=>1,
        "Gene Pipeline efficiency (%)"=>"100",
        "Clone Pipeline efficiency (%)"=>"20",
        "Phenotype Registrations"=>1,
        "Rederivation Starts"=>1,
        "Rederivation Completes"=>1,
        "Cre Excision Starts"=>3,
        "Cre Excision Complete"=>2,
        "Phenotype data starts"=>1,
        "Phenotyping Complete"=>1,
        "Phenotype Attempt Aborted"=>1
      }

      report.column_names.each do |column_name|
        puts "expected: KEY: '#{column_name}' - VALUE: '#{report.column(column_name)[0]}'" if DEBUG
        assert_equal expected[column_name], report.column(column_name)[0]
      end
      
      assert report.to_s.length > 0
    end
    
    should 'do generate detail' do
      puts 'do generate detail:' if DEBUG
      
      title2, report = Reports::MiProduction::SummaryKomp23.subsummary(:consortium => 'BaSH', :pcentre => 'BCM', :type => 'All')

      puts report.data.inspect if DEBUG

      assert report.to_s.length > 0      
    end

  end

end
