# encoding: utf-8

require 'test_helper'

class Reports::MiProduction::SummaryKomp2BriefTest < ActiveSupport::TestCase

  DEBUG = false
  
  context 'Reports::MiProduction::SummaryKomp2Brief' do

    setup do
      assert ! ReportCache.find_by_name('mi_production_intermediate')
      ReportCache.create!(
        :name => 'mi_production_intermediate',
        :csv_data => ProductionSummaryHelper::get_csv('komp2 brief')
      )
      assert ReportCache.find_by_name('mi_production_intermediate')      
      report = ReportCache.find_by_name!('mi_production_intermediate').to_table
      
      puts 'SETUP:' if DEBUG
      puts report.to_s if DEBUG
      assert report
    end
    
    should 'do generate' do
      title2, report = Reports::MiProduction::SummaryKomp2Brief.generate(nil, {'debug'=>'true'})
      
      puts 'do generate: ' + title2 if DEBUG
      puts report.to_s if DEBUG

      puts "report size: #{report.size}" if DEBUG
      puts "report column_names:" + report.column_names.inspect if DEBUG
      
      report = ProductionSummaryHelper::de_tag_table(report)
      puts report.to_s if DEBUG
      
      assert_equal 1, report.size
      
      expecteds = ProductionSummaryHelper::get_expecteds 'komp2 brief'
    
      expecteds.each_pair do |k,v|
        puts "#{k} : #{v}" if DEBUG
        assert_equal v.to_s, report.column(k)[0]
      end
            
    end
    
    should 'do generate detail' do
      puts 'do generate detail:' if DEBUG

      expecteds = ProductionSummaryHelper::get_expecteds 'komp2 brief'
            
      expecteds.each_pair do |k,v|
        next if k == 'Pipeline efficiency (%)'
        puts "#{k} : #{v}" if DEBUG
        title2, report = Reports::MiProduction::SummaryKomp2Brief.subsummary_common(nil, { :consortium => 'BaSH', :type => k })
        puts "report size: #{report.size}" if DEBUG
        puts report.to_s if DEBUG
        assert_equal v, report.size
      end
      
    end

  end

end
