# encoding: utf-8

require 'test_helper'

class Reports::MiProductionTest < ActiveSupport::TestCase

  context 'Reports::MiProduction::GeneSummary' do

    should 'get table' do

      gene_cbx1 = Factory.create :gene_cbx1

      #      Factory.create :mi_plan, :gene => gene_cbx1,
      #        :consortium => Consortium.find_by_name('BaSH'),
      #        :production_centre => Centre.find_by_name('WTSI'),
      #        :mi_plan_status => MiPlanStatus['Assigned']
      #
      #      Factory.create :mi_plan, :gene => gene_cbx1,
      #        :consortium => Consortium.find_by_name('JAX'),
      #        :production_centre => Centre.find_by_name('JAX'),
      #        :number_of_es_cells_starting_qc => 5

      gene = Factory.create :gene,
        :marker_symbol => 'Moo1',
        :mgi_accession_id => 'MGI:12345'

      #      mi = Factory.create :wtsi_mi_attempt_genotype_confirmed,
      #        :es_cell => Factory.create(:es_cell, :gene => gene),
      #        :consortium_name => 'EUCOMM-EUMODIC',
      #        :is_active => true
      #
      #      mi = Factory.create :wtsi_mi_attempt_genotype_confirmed,
      #        :es_cell => Factory.create(:es_cell, :gene => gene),
      #        :consortium_name => 'JAX'

      #      Factory.create :mi_attempt,
      #        :es_cell => Factory.create(:es_cell, :gene => gene),
      #        :consortium_name => 'MGP',
      #        :production_centre_name => 'WTSI',
      #        :is_active => true

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

      #      params = {"utf8"=>"✓", "format"=>"html", "commit"=>"true", "controller"=>"reports", "action"=>"mi_attempts_by_gene"}
      params = {"utf8"=>"✓", "format"=>"html", "controller"=>"reports", "action"=>"mi_attempts_by_gene"}

      report = Reports::MiProduction::GeneSummary.get_list(params)

      puts "\nREPORT:\n\n" + report.to_s

      #      puts "\nREPORT:\n\n" + report[0].to_s
      #      puts "\nREPORT:\n\n" + report[1].to_s

      assert !report.blank?

      #   report = Reports::MiProduction::GeneSummary.generate_mi_list_report(params)

      #   puts "\nREPORT 2 :\n\n" + report.to_s

      #   puts Consortium.all.inspect
      #   puts Centre.all.inspect

      #+-------------------------------------------------------------------------------------------------------+
      #|   Consortium   | Production Centre | # Genes Injected | # Genes Genotype Confirmed | # Genes For EMMA |
      #+-------------------------------------------------------------------------------------------------------+
      #| MGP            | WTSI              |                1 |                          1 |                1 |
      #| EUCOMM-EUMODIC | WTSI              |                1 |                          1 |                1 |
      #+-------------------------------------------------------------------------------------------------------+

      assert_equal 'MGP', report.column('Consortium')[0]
      assert_equal 'WTSI', report.column('Production Centre')[0]
      assert_equal 1, report.column('# Genes Injected')[0]
      assert_equal 1, report.column('# Genes Genotype Confirmed')[0]
      assert_equal 1, report.column('# Genes For EMMA')[0]

      assert_equal 'EUCOMM-EUMODIC', report.column('Consortium')[1]
      assert_equal 'WTSI', report.column('Production Centre')[1]
      assert_equal 2, report.column('# Genes Injected')[1]
      assert_equal 2, report.column('# Genes Genotype Confirmed')[1]
      assert_equal 2, report.column('# Genes For EMMA')[1]

    end

  end

end
