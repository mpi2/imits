# encoding: utf-8

require 'test_helper'

class Reports::MiAttemptsMonthlyProductionTest < ActiveSupport::TestCase

  context 'Reports::MiAttemptsMonthlyProduction::Summary' do

    should 'get table' do

      gene_cbx1 = Factory.create :gene_cbx1

      #gene = Factory.create :gene,
      #  :marker_symbol => 'Moo1',
      #  :mgi_accession_id => 'MGI:12345'

      Factory.create :wtsi_mi_attempt_genotype_confirmed,
        :es_cell => Factory.create(:es_cell, :gene => gene_cbx1),
        :consortium_name => 'MGP',
        :is_active => true,
        :is_suitable_for_emma => true,
        :total_pups_born => 10,
        :total_male_chimeras => 10

      #Factory.create :wtsi_mi_attempt_genotype_confirmed,
      #  :es_cell => Factory.create(:es_cell, :gene => gene),
      #  :consortium_name => 'EUCOMM-EUMODIC',
      #  :is_active => true,
      #  :is_suitable_for_emma => true
      #
      #Factory.create :wtsi_mi_attempt_genotype_confirmed,
      #  :es_cell => Factory.create(:es_cell, :gene => gene_cbx1),
      #  :consortium_name => 'EUCOMM-EUMODIC',
      #  :is_active => true,
      #  :is_suitable_for_emma => true

      params = {"utf8"=>"✓", "format"=>"html", "controller"=>"reports", "action"=>"mi_attempts_monthly_production"}
      
      report = Reports::MiAttemptsMonthlyProduction::Summary.get(nil, params)
      
      assert !report.blank?
      
      puts report.to_s

      #+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
      #| Consortium | Production Centre | Month Injected | # Clones Injected | # at Birth | % of Injected (at Birth) | # at Weaning | # Clones Genotype Confirmed | % Clones Genotype Confirmed |
      #+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
      #| MGP        | WTSI              | 2011-11        |                 1 |          1 |                      100 |            1 |                           1 |                         100 |
      #+----------------------------------------------------------------------------------------------------------------------------------------------------------------------------------------+
      
      #puts report.column('Consortium')[0]
      #puts report.column('Consortium')[1]

      assert_equal 'MGP', report.column('Consortium')[0]
      assert_equal 'WTSI', report.column('Production Centre')[0]
      assert_equal '2011-11', report.column('Month Injected')[0]
      assert_equal 1, report.column('# Clones Injected')[0]
      assert_equal 1, report.column('# at Birth')[0]
      assert_equal 100, report.column('% of Injected (at Birth)')[0]
      assert_equal 1, report.column('# at Weaning')[0]
      assert_equal 1, report.column('# Clones Genotype Confirmed')[0]
      assert_equal 100, report.column('% Clones Genotype Confirmed')[0]
      
      #assert_equal 'EUCOMM-EUMODIC', report.column('Consortium')[0]
      #assert_equal 'WTSI', report.column('Production Centre')[0]
      #assert_equal 2, report.column('# Genes Injected')[0]
      #assert_equal 2, report.column('# Genes Genotype Confirmed')[0]
      #assert_equal 2, report.column('# Genes For EMMA')[0]

    end

  end

end
