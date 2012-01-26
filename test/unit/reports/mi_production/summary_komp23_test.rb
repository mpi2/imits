# encoding: utf-8

require 'test_helper'

class Reports::MiProduction::SummaryKomp23Test < ActiveSupport::TestCase

  DEBUG = false
  
  context 'Reports::MiProduction::SummaryKomp23' do

    setup do
      assert ! ReportCache.find_by_name('mi_production_intermediate')
      data = ProductionSummaryHelper::get_csv('komp2')
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

      #[#<Ruport::Data::Record:0xb66cb90
      #@attributes=["Consortium", "All Genes", "ES QCs", "ES QC confirms", "ES QC Failures", "Production Centre", "MIs", "Chimaeras", "Genotype Confirmed", "MI Aborted", "Gene Pipeline efficiency (%)", "Clone Pipeline efficiency (%)", "Phenotype Registrations", "Rederivation Starts", "Rederivation Completes", "Cre Excision Starts", "Cre Excision Complete", "Phenotype data starts", "Phenotyping Complete", "Phenotype Attempt Aborted"],

      expected = {
        "Consortium"=>"BaSH",
        "All Genes"=>7,
        "ES QCs"=>3,
        "ES QC confirms"=>1,
        "ES QC Failures"=>1,
        "Production Centre"=>"BCM",
        "MIs"=>4,
        "Chimaeras"=>nil,
        "Genotype Confirmed"=>1,
        "MI Aborted"=>1,
        "Gene Pipeline efficiency (%)"=>"",
        "Clone Pipeline efficiency (%)"=>"",
        "Phenotype Registrations"=>"",
        "Rederivation Starts"=>nil,
        "Rederivation Completes"=>"",
        "Cre Excision Starts"=>nil,
        "Cre Excision Complete"=>"",
        "Phenotype data starts"=>"",
        "Phenotyping Complete"=>"",
        "Phenotype Attempt Aborted"=>""
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
