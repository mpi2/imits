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
      hash = Reports::MiProduction::SummaryKomp23.generate({:live => true})
      
      puts 'do generate: ' + hash[:title] if DEBUG
      puts hash[:table].to_s if DEBUG
      puts hash[:table].data.inspect if DEBUG

      expected = {
        "Consortium"=>"BaSH",
        "All genes"=>11,
        "ES cell QC"=>3,
        "ES QC confirmed"=>2,
        "ES QC failed"=>1,
        "Production Centre"=>"BCM",
        "Microinjections"=>10,
        "Chimaeras produced"=>nil,
        "Genotype confirmed mice"=>1,
        "Microinjection aborted"=>1,
        "Gene Pipeline efficiency (%)"=>"100",
        "Clone Pipeline efficiency (%)"=>"20",
        "Registered for phenotyping"=>1,
        "Rederivation started"=>1,
        "Rederivation completed"=>1,
        "Cre excision started"=>3,
        "Cre excision completed"=>2,
        "Phenotyping started"=>1,
        "Phenotyping completed"=>1,
        "Phenotyping aborted"=>1
      }

      hash[:table].column_names.each do |column_name|
        assert_equal expected[column_name], hash[:table].column(column_name)[0], "for '#{column_name}'"
      end
      
      assert hash[:table].to_s.length > 0
    end
    
    should 'do generate detail' do
      puts 'do generate detail:' if DEBUG
      
      title2, report = Reports::MiProduction::SummaryKomp23.subsummary(:consortium => 'BaSH', :pcentre => 'BCM', :type => 'All')

      puts report.data.inspect if DEBUG

      assert report.to_s.length > 0      
    end

  end

end
