# encoding: utf-8

require 'test_helper'

class Reports::MiAttemptsMonthlyProductionTest < ActiveSupport::TestCase

  context 'Reports::MiAttemptsMonthlyProduction::Summary' do

    should 'get table' do

      gene_cbx1 = Factory.create :gene_cbx1

      Factory.create :wtsi_mi_attempt_genotype_confirmed,
        :es_cell => Factory.create(:es_cell, :gene => gene_cbx1),
        :consortium_name => 'MGP',
        :is_active => true,
        :is_suitable_for_emma => true,
        :total_pups_born => 10,
        :total_male_chimeras => 10

      params = {"utf8"=>"✓", "format"=>"html", "controller"=>"reports", "action"=>"mi_attempts_monthly_production"}
      
      report = Reports::MiAttemptsMonthlyProduction::Summary.generate(nil, params)
      
      assert !report.blank?
      
      assert_equal 'MGP', report.column('Consortium')[0]
      assert_equal 'WTSI', report.column('Production Centre')[0]
      assert_equal 1, report.column('# Clones Injected')[0]
      assert_equal 1, report.column('# at Birth')[0]
      assert_equal 100, report.column('% of Injected (at Birth)')[0]
      assert_equal 1, report.column('# at Weaning')[0]
      assert_equal 1, report.column('# Clones Genotype Confirmed')[0]
      assert_equal 100, report.column('% Clones Genotype Confirmed')[0]

    end

  end

end
