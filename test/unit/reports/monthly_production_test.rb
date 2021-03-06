# encoding: utf-8

require 'test_helper'

class Reports::MonthlyProductionTest < ActiveSupport::TestCase

  context 'Reports::MonthlyProduction' do

    should 'get table' do

      allele = Factory.create :allele, :gene => cbx1

      Factory.create :mi_attempt2_status_gtc,
        :es_cell => Factory.create(:es_cell, :allele => allele),
        :mi_plan => TestDummy.mi_plan('MGP', 'WTSI', :gene => cbx1, :force_assignment => true),
        :is_active => true,
        :total_pups_born => 10,
        :total_male_chimeras => 10

      report = Reports::MonthlyProduction.generate

      assert !report.blank?

      assert_equal 'MGP', report.column('Consortium')[0]
      assert_equal 'WTSI', report.column('Production Centre')[0]
      assert_equal 1, report.column('# Clones Injected')[0]
      assert_equal 1, report.column('# at Birth')[0]
      assert_equal 100, report.column('% at Birth')[0]
      assert_equal 1, report.column('# at Weaning')[0]
      assert_equal 1, report.column('# Genotype Confirmed')[0]
      assert_equal 100, report.column('% Genotype Confirmed')[0]

    end

  end

end
