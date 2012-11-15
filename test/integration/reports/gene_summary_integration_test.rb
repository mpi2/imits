# encoding: utf-8

require 'test_helper'

class Reports::GeneSummaryIntegrationTest < Kermits2::IntegrationTest

  context 'reports/mi_attempts_by_gene' do

    context 'once logged in' do
      setup do
        visit '/users/logout'
        login
      end

      should 'allow users to visit the correct page & see entries' do

        visit '/reports/mi_attempts_by_gene'
        assert_match '/reports/mi_attempts_by_gene', current_url

        gene_moo1 = Factory.create :gene,
          :marker_symbol => 'Moo1',
          :mgi_accession_id => 'MGI:12345'

        Factory.create :wtsi_mi_attempt_genotype_confirmed,
          :es_cell => Factory.create(:es_cell, :allele => Factory.create(:allele, :gene => gene_moo1)),
          :consortium_name => 'EUCOMM-EUMODIC',
          :is_active => true

        Factory.create :wtsi_mi_attempt_genotype_confirmed,
          :es_cell => Factory.create(:es_cell, :allele => Factory.create(:allele_with_gene_cbx1)),
          :consortium_name => 'EUCOMM-EUMODIC',
          :is_active => true

        click_button 'Generate Report'

        assert page.has_content? "Consortium Production Centre # Genes Injected # Genes Genotype Confirmed"

        assert page.has_css?('div.report tr:nth-child(1) th:nth-child(1)', :text => 'Consortium')
        assert page.has_css?('div.report tr:nth-child(1) th:nth-child(2)', :text => 'Production Centre')
        assert page.has_css?('div.report tr:nth-child(1) th:nth-child(3)', :text => '# Genes Injected')
        assert page.has_css?('div.report tr:nth-child(1) th:nth-child(4)', :text => '# Genes Genotype Confirmed')

        assert page.has_css?('div.report tr:nth-child(2) td:nth-child(1)', :text => 'EUCOMM-EUMODIC')
        assert page.has_css?('div.report tr:nth-child(2) td:nth-child(2)', :text => 'WTSI')
        assert page.has_css?('div.report tr:nth-child(2) td:nth-child(3)', :text => '2')
        assert page.has_css?('div.report tr:nth-child(2) td:nth-child(4)', :text => '2')

      end

    end

  end
end
