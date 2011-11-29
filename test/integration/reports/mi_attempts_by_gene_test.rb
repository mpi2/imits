# encoding: utf-8

require 'test_helper'

class Reports::MiProductionTest < ActionDispatch::IntegrationTest

  context 'Reports::MiProduction::GeneSummary' do

    context 'once logged in' do
      setup do
        #  create_common_test_objects
        visit '/users/logout'
        login
      end

      should 'allow users to visit the correct page & see entries' do
        
        visit '/reports/mi_attempts_by_gene'
        assert_match '/reports/mi_attempts_by_gene', current_url

        gene_cbx1 = Factory.create :gene_cbx1

        gene_moo1 = Factory.create :gene,
          :marker_symbol => 'Moo1',
          :mgi_accession_id => 'MGI:12345'

        #        Factory.create :wtsi_mi_attempt_genotype_confirmed,
        #          :es_cell => Factory.create(:es_cell, :gene => gene),
        #          :consortium_name => 'MGP',
        #          :is_active => true,
        #          :is_suitable_for_emma => true

        Factory.create :wtsi_mi_attempt_genotype_confirmed,
          :es_cell => Factory.create(:es_cell, :gene => gene_moo1),
          :consortium_name => 'EUCOMM-EUMODIC',
          :is_active => true,
          :is_suitable_for_emma => true

        Factory.create :wtsi_mi_attempt_genotype_confirmed,
          :es_cell => Factory.create(:es_cell, :gene => gene_cbx1),
          :consortium_name => 'EUCOMM-EUMODIC',
          :is_active => true,
          :is_suitable_for_emma => true

        click_button 'Generate Report'

        save_and_open_page

        #+-------------------------------------------------------------------------------------------------------+
        #|   Consortium   | Production Centre | # Genes Injected | # Genes Genotype Confirmed | # Genes For EMMA |
        #+-------------------------------------------------------------------------------------------------------+
        #| EUCOMM-EUMODIC | WTSI              |                2 |                          2 |                2 |
        #+-------------------------------------------------------------------------------------------------------+

        #                 puts "\nREPORT :\n\n" + report.to_s

        #   assert page.has_content? "Marker Symbol Consortium Plan Status MI Status Centre MI Date"
        #   assert page.has_content? "Cbx1 BaSH Assigned"

        #assert page.has_css?('div#double-matrix tr:nth-child(2) td:nth-child(4)', :text => '1')

        #assert page.has_content? "Marker Symbol Consortium Plan Status MI Status Centre MI Date"

        assert page.has_content? "Consortium Production Centre # Genes Injected # Genes Genotype Confirmed # Genes For EMMA"

        assert page.has_css?('div.grid_12 tr:nth-child(1) th:nth-child(1)', :text => 'Consortium')
        assert page.has_css?('div.grid_12 tr:nth-child(1) th:nth-child(2)', :text => 'Production Centre')
        assert page.has_css?('div.grid_12 tr:nth-child(1) th:nth-child(3)', :text => '# Genes Injected')
        assert page.has_css?('div.grid_12 tr:nth-child(1) th:nth-child(4)', :text => '# Genes Genotype Confirmed')
        assert page.has_css?('div.grid_12 tr:nth-child(1) th:nth-child(5)', :text => '# Genes For EMMA')

        assert page.has_css?('div.grid_12 tr:nth-child(2) td:nth-child(1)', :text => 'EUCOMM-EUMODIC')
        assert page.has_css?('div.grid_12 tr:nth-child(2) td:nth-child(2)', :text => 'WTSI')
        assert page.has_css?('div.grid_12 tr:nth-child(2) td:nth-child(3)', :text => '2')
        assert page.has_css?('div.grid_12 tr:nth-child(2) td:nth-child(4)', :text => '2')
        assert page.has_css?('div.grid_12 tr:nth-child(2) td:nth-child(5)', :text => '2')

      end

    end

  end
end
