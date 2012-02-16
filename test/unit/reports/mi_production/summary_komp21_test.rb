# encoding: utf-8

require 'test_helper'

class Reports::MiProduction::SummaryKomp21Test < ActiveSupport::TestCase

  DEBUG = false

  context 'Reports::MiProduction::SummaryKomp21' do

    setup do
      assert ! ReportCache.find_by_name('mi_production_intermediate')
      data = ProductionSummaryHelper::get_csv('komp2')
      assert data
      Factory.create(:report_cache,
        :name => 'mi_production_intermediate',
        :data => data
      )
      assert ReportCache.find_by_name('mi_production_intermediate')
      report = ReportCache.find_by_name!('mi_production_intermediate').to_table

      puts 'SETUP:' if DEBUG
      puts report.to_s if DEBUG
      assert report

      #create_common_test_objects
      #visit '/users/logout'
      #login
    end

    should 'do generate'
    #do
      #title2, report = Reports::MiProduction::SummaryKomp21.generate(nil, {'debug'=>'true'})
      #
      #puts 'do generate: ' + title2 if DEBUG
      #puts report.to_s if DEBUG
      #
      #assert report.to_s.length > 0
    #end

    should 'do generate detail'
    #do
      #puts 'do generate detail:' if DEBUG
      #
      #expecteds = ProductionSummaryHelper::get_expecteds 'Komp21'
      #
      #expecteds.each_pair do |k,v|
      #  next if k == 'Pipeline efficiency (%)'
      #  next if k == 'Production Centre'
      #  puts "#{k} : #{v}" if DEBUG
      #  title2, report = Reports::MiProduction::SummaryKomp21.subsummary_common(:consortium => 'BaSH', :type => k)
      #  puts "report size: #{report.size}" if DEBUG
      #  puts report.to_s if DEBUG
      #  assert_equal v, report.size
      #end

    #end

  end

end
