# encoding: utf-8

require 'test_helper'

class Reports::MiProduction::SummaryByConsortiumPriorityPriorityTest < ActiveSupport::TestCase

  DEBUG = false

  context 'Reports::MiProduction::SummaryByConsortiumPriority' do

    setup do
      assert ! ReportCache.find_by_name('mi_production_intermediate')
      Factory.create(:report_cache,
        :name => 'mi_production_intermediate',
        :data => ProductionSummaryHelper::get_csv('summary by consortium priority')
      )
      assert ReportCache.find_by_name('mi_production_intermediate')
      report = ReportCache.find_by_name!('mi_production_intermediate').to_table

      puts 'SETUP:' if DEBUG
      puts report.to_s if DEBUG
      assert report
    end

    should 'do generate' do
      title2, report = Reports::MiProduction::SummaryByConsortiumPriority.generate(nil, {'debug'=>'true'})

      puts 'do generate: ' + title2 if DEBUG
      puts report.to_s if DEBUG

      puts "report size: #{report.size}" if DEBUG
      puts "report column_names:" + report.column_names.inspect if DEBUG

      report = ProductionSummaryHelper::de_tag_table(report)
      puts report.to_s if DEBUG

      assert_equal 1, report.size

      expecteds = ProductionSummaryHelper::get_expecteds 'summary by consortium priority'

      expecteds.each_pair do |k,v|
        puts "#{k} : #{v}" if DEBUG
        assert_equal v.to_s, report.column(k)[0]
      end

    end

    should 'do generate detail' do
      puts 'do generate detail:' if DEBUG

      expecteds = ProductionSummaryHelper::get_expecteds 'summary by consortium priority'

      expecteds.each_pair do |k,v|
        next if k == 'Pipeline efficiency (%)'
        next if k == 'Priority'
        puts "#{k} : #{v}" if DEBUG
        title2, report = Reports::MiProduction::SummaryByConsortiumPriority.subsummary_common(:consortium => 'BaSH', :type => k)
        puts "report size: #{report.size}" if DEBUG
        puts report.to_s if DEBUG
        assert_equal v, report.size
      end

    end

  end

end
