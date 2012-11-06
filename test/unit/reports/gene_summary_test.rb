# encoding: utf-8

require 'test_helper'

class Reports::GeneSummaryTest < ActiveSupport::TestCase

  context 'Reports::MiAttemptsByGene::GeneSummary' do

    should 'get table' do

      allele = Factory.create :allele_with_gene_cbx1

      gene = Factory.create :gene,
        :marker_symbol => 'Moo1',
        :mgi_accession_id => 'MGI:12345'

      allele_with_moo1 = Factory.create(:allele, :gene => gene)

      Factory.create :wtsi_mi_attempt_genotype_confirmed,
        :es_cell => Factory.create(:es_cell, :allele => allele_with_moo1),
        :consortium_name => 'MGP',
        :is_active => true

      Factory.create :wtsi_mi_attempt_genotype_confirmed,
        :es_cell => Factory.create(:es_cell, :allele => allele_with_moo1),
        :consortium_name => 'EUCOMM-EUMODIC',
        :is_active => true

      Factory.create :wtsi_mi_attempt_genotype_confirmed,
        :es_cell => Factory.create(:es_cell, :allele => allele),
        :consortium_name => 'EUCOMM-EUMODIC',
        :is_active => true

      report = Reports::GeneSummary.generate()

      assert !report.blank?

      assert_equal 'MGP', report.column('Consortium')[1]
      assert_equal 'WTSI', report.column('Production Centre')[1]
      assert_equal 1, report.column('# Genes Injected')[1]
      assert_equal 1, report.column('# Genes Genotype Confirmed')[1]

      assert_equal 'EUCOMM-EUMODIC', report.column('Consortium')[0]
      assert_equal 'WTSI', report.column('Production Centre')[0]
      assert_equal 2, report.column('# Genes Injected')[0]
      assert_equal 2, report.column('# Genes Genotype Confirmed')[0]

    end

  end

end
