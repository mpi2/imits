# encoding: utf-8

require 'test_helper'

class Reports::GeneSummaryTest < ActiveSupport::TestCase

  context 'Reports::MiAttemptsByGene::GeneSummary' do

    should 'get table' do

      gene_cbx1 = Factory.create :gene_cbx1

      gene = Factory.create :gene,
        :marker_symbol => 'Moo1',
        :mgi_accession_id => 'MGI:12345'

      Factory.create :wtsi_mi_attempt_genotype_confirmed,
        :es_cell => Factory.create(:es_cell, :gene => gene),
        :consortium_name => 'MGP',
        :is_active => true,
        :is_suitable_for_emma => true

      Factory.create :wtsi_mi_attempt_genotype_confirmed,
        :es_cell => Factory.create(:es_cell, :gene => gene),
        :consortium_name => 'EUCOMM-EUMODIC',
        :is_active => true,
        :is_suitable_for_emma => true

      Factory.create :wtsi_mi_attempt_genotype_confirmed,
        :es_cell => Factory.create(:es_cell, :gene => gene_cbx1),
        :consortium_name => 'EUCOMM-EUMODIC',
        :is_active => true,
        :is_suitable_for_emma => true

      params = {"utf8"=>"✓", "format"=>"html", "controller"=>"reports", "action"=>"mi_attempts_by_gene"}

      report = Reports::GeneSummary.generate(nil, params)

      assert !report.blank?

      assert_equal 'MGP', report.column('Consortium')[1]
      assert_equal 'WTSI', report.column('Production Centre')[1]
      assert_equal 1, report.column('# Genes Injected')[1]
      assert_equal 1, report.column('# Genes Genotype Confirmed')[1]
      assert_equal 1, report.column('# Genes For EMMA')[1]

      assert_equal 'EUCOMM-EUMODIC', report.column('Consortium')[0]
      assert_equal 'WTSI', report.column('Production Centre')[0]
      assert_equal 2, report.column('# Genes Injected')[0]
      assert_equal 2, report.column('# Genes Genotype Confirmed')[0]
      assert_equal 2, report.column('# Genes For EMMA')[0]

    end

  end

end
