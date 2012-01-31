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
        "All genes"=>11,
        "ES cell QC"=>3,
        "ES QC confirmed"=>2,
        "ES QC failed"=>1,
        "Production Centre"=>"BCM",
        "Microinjections"=>9,
        "Chimaeras produced"=>nil,
        "Genotype confirmed mice"=>"",
        "Microinjection aborted"=>1,
        "Gene Pipeline efficiency (%)"=>"",
        "Clone Pipeline efficiency (%)"=>"",
        "Registered for phenotyping"=>1,
        "Rederivation started"=>1,
        "Rederivation completed"=>1,
        "Cre excision started"=>1,
        "Cre excision completed"=>"",
        "Phenotyping started"=>"",
        "Phenotyping completed"=>"",
        "Phenotyping aborted"=>""
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
