# encoding: utf-8

require 'test_helper'

class Reports::MiProduction::SummaryKomp2Test < ActiveSupport::TestCase

  DEBUG = false
  
  context 'Reports::MiProduction::SummaryKomp2' do

    setup do
      assert ! ReportCache.find_by_name('mi_production_intermediate')
      ReportCache.create!(
        :name => 'mi_production_intermediate',
        :csv_data => ProductionSummaryHelper::get_csv('komp2')
      )
      assert ReportCache.find_by_name('mi_production_intermediate')      
      report = ReportCache.find_by_name!('mi_production_intermediate').to_table
      
      puts 'SETUP:' if DEBUG
      puts report.to_s if DEBUG
      assert report
    end
    
    should 'do generate' do
      title2, report = Reports::MiProduction::SummaryKomp2.generate(nil, {'debug'=>'true'})
      
      puts 'do generate: ' + title2 if DEBUG
      puts report.to_s if DEBUG
      
      assert report.to_s.length > 0

    end
    
    should 'do generate detail' do
      puts 'do generate detail:' if DEBUG

      expecteds = ProductionSummaryHelper::get_expecteds 'komp2'
            
      expecteds.each_pair do |k,v|
        next if k == 'Pipeline efficiency (%)'
        next if k == 'Production Centre'
        puts "#{k} : #{v}" if DEBUG
        title2, report = Reports::MiProduction::SummaryKomp2.subsummary_common(:consortium => 'BaSH', :type => k)
        puts "report size: #{report.size}" if DEBUG
        puts report.to_s if DEBUG
        assert_equal v, report.size
      end
      
    end

  end

end
