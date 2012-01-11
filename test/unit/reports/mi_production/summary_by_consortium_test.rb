# encoding: utf-8

require 'test_helper'

class Reports::MiProduction::SummaryByConsortiumTest < ProductionSummaryHelper
  
  DEBUG = false

  expecteds = {
    'All' => 7,
    'ES QC started' => 1,
    'ES QC confirmed' => 1,
    'ES QC failed' => 1,
    'MI in progress' => 2,
    'MI Aborted' => 1,
    'Genotype Confirmed Mice' => 1,
    'Pipeline efficiency (%)' => 33
  }

  context 'Reports::MiProduction::SummaryByConsortium' do

    setup do
      assert ! ReportCache.find_by_name('mi_production_intermediate')
      ReportCache.create!(
        :name => 'mi_production_intermediate',
        :csv_data => get_csv
      )
      assert ReportCache.find_by_name('mi_production_intermediate')      
      report = ReportCache.find_by_name!('mi_production_intermediate').to_table
      
      puts 'SETUP:' if DEBUG
      puts report.to_s if DEBUG
      assert report
    end
    
    should 'do generate' do
      title2, report = Reports::MiProduction::SummaryByConsortium.generate(nil, {'debug'=>'true'}, nil)
      
      puts 'do generate: ' + title2 if DEBUG
      puts report.to_s if DEBUG

      puts "report size: #{report.size}" if DEBUG
      puts "report column_names:" + report.column_names.inspect if DEBUG
      
      report = de_tag_table(report)
      puts report.to_s if DEBUG
      
      assert_equal 1, report.size
    
      expecteds.each_pair do |k,v|
        puts "#{k} : #{v}" if DEBUG
        assert_equal v.to_s, report.column(k)[0]
      end
            
    end
    
    should 'do generate detail' do
      puts 'do generate detail:' if DEBUG
            
      expecteds.each_pair do |k,v|
        next if k == 'Pipeline efficiency (%)'
        puts "#{k} : #{v}" if DEBUG
        title2, report = Reports::MiProduction::SummaryByConsortium.subsummary_common(nil, { :consortium => 'BaSH', :type => k })
        puts "report size: #{report.size}" if DEBUG
        puts report.to_s if DEBUG
        assert_equal v, report.size
      end
      
    end

  end

end
