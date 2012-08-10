# encoding: utf-8

require 'test_helper'

class QualityOverviewGrouping::ViewIndexIntegrationTest < Kermits2::IntegrationTest

  context 'QualityOverviewGrouping view index' do

    context 'once logged in' do
      setup do
        visit '/users/logout'
        login
      end

      should 'allow users to visit the correct page & see entries' do

        #row 1
        gene_tpi1 = Factory.create :gene, :marker_symbol => 'Tpi1', :mgi_accession_id => 'MGI:98797', :ikmc_projects_count => 3, :conditional_es_cells_count => 11,
        :non_conditional_es_cells_count => 8, :deletion_es_cells_count => 6, :other_targeted_mice_count => nil, :other_condtional_mice_count => nil, :mutation_published_as_lethal_count => nil,
        :publications_for_gene_count => nil, :go_annotations_for_gene_count => nil

        pipeline = Pipeline.find_by_name! 'EUCOMM'
        es_cell_tpi1 = Factory.create :es_cell, :name => 'EPD0183_4_A09', :allele_symbol_superscript_template => 'tm1@(EUCOMM)Wtsi', :allele_type => 'a', :pipeline => pipeline,
        :gene => gene_tpi1, :parental_cell_line => 'JM8.N4', :mutation_subtype => "conditional_ready"

        centre = Centre.find_by_name! 'CNB'
        mi_attempt_distribution_centre = Factory.create :mi_attempt_distribution_centre, :centre => centre, :is_distributed_by_emma => true
        mi_attempt_tpi1 = Factory.create :wtsi_mi_attempt_genotype_confirmed, :es_cell => es_cell_tpi1, :colony_name => 'MCFC', :production_centre_name => 'WTSI',
        :number_of_het_offspring => 2

        mi_attempt_tpi1.distribution_centres.push(mi_attempt_distribution_centre)
        mi_attempt_tpi1.save!

        #row 2
        gene_celsr3 = Factory.create :gene, :marker_symbol => 'Celsr3', :mgi_accession_id => 'MGI:1858236', :ikmc_projects_count => 2, :conditional_es_cells_count => nil,
        :non_conditional_es_cells_count => nil, :deletion_es_cells_count => 2, :other_targeted_mice_count => nil, :other_condtional_mice_count => nil, :mutation_published_as_lethal_count => nil,
        :publications_for_gene_count => nil, :go_annotations_for_gene_count => nil

        Factory.create :pipeline, :name => 'KOMP-Regeneron'
        pipeline = Pipeline.find_by_name! 'KOMP-Regeneron'
        es_cell_celsr3 = Factory.create :es_cell, :name => '10009A-F9', :allele_symbol_superscript_template => 'tm1(KOMP)Vlcg', :allele_type => nil, :pipeline => pipeline,
        :gene => gene_celsr3, :parental_cell_line => 'VGB6', :mutation_subtype => 'deletion'

        centre = Centre.find_by_name! 'UCD'
        mi_attempt_distribution_centre = Factory.create :mi_attempt_distribution_centre, :centre => centre, :is_distributed_by_emma => true
        mi_attempt_celsr3 = Factory.create :mi_attempt_genotype_confirmed, :es_cell => es_cell_celsr3, :colony_name => 'UCD-10009A-F9-1', :production_centre_name => 'UCD',
        :number_of_het_offspring => 2

        mi_attempt_celsr3.distribution_centres.push(mi_attempt_distribution_centre)
        mi_attempt_celsr3.save!

        #row 3
        gene_lgi2 = Factory.create :gene, :marker_symbol => 'Lgi2', :mgi_accession_id => 'MGI:2180196', :ikmc_projects_count => 2, :conditional_es_cells_count => 12,
        :non_conditional_es_cells_count => 4, :deletion_es_cells_count => 5, :other_targeted_mice_count => nil, :other_condtional_mice_count => nil, :mutation_published_as_lethal_count => nil,
        :publications_for_gene_count => nil, :go_annotations_for_gene_count => nil

        pipeline = Pipeline.find_by_name! 'KOMP-Regeneron'
        es_cell_lgi2 = Factory.create :es_cell, :name => '10011B-G3', :allele_symbol_superscript_template => 'tm1(KOMP)Vlcg', :allele_type => nil, :pipeline => pipeline,
        :gene => gene_lgi2, :parental_cell_line => 'VGB6', :mutation_subtype => 'deletion'

        centre = Centre.find_by_name! 'UCD'
        mi_attempt_distribution_centre = Factory.create :mi_attempt_distribution_centre, :centre => centre, :is_distributed_by_emma => true
        mi_attempt_lgi2 = Factory.create :mi_attempt_genotype_confirmed, :es_cell => es_cell_lgi2, :colony_name => 'BL1071', :production_centre_name => 'UCD',
        :number_of_het_offspring => 2

        mi_attempt_lgi2.distribution_centres.push(mi_attempt_distribution_centre)
        mi_attempt_lgi2.save!

        visit '/quality_overview_groupings'
        assert_match '/quality_overview_groupings', current_url

        assert page.has_css?('div.quality-overviews-summary')

        assert page.has_css?('div.quality-overviews-summary tr:nth-child(1) th:nth-child(1)', :text => 'Consortia Group')
        assert page.has_css?('div.quality-overviews-summary tr:nth-child(1) th:nth-child(2)', :text => 'Consortium')
        assert page.has_css?('div.quality-overviews-summary tr:nth-child(1) th:nth-child(3)', :text => 'Production centre')
        assert page.has_css?('div.quality-overviews-summary tr:nth-child(1) th:nth-child(4)', :text => 'Genotype confirmed colonies')
        assert page.has_css?('div.quality-overviews-summary tr:nth-child(1) th:nth-child(5)', :text => 'Colonies with overall pass')
        assert page.has_css?('div.quality-overviews-summary tr:nth-child(1) th:nth-child(6)', :text => '% Overall Pass colonies')
        assert page.has_css?('div.quality-overviews-summary tr:nth-child(1) th:nth-child(7)', :text => 'Locus targeted fails')
        assert page.has_css?('div.quality-overviews-summary tr:nth-child(1) th:nth-child(8)', :text => 'Structure targeted allele fails')
        assert page.has_css?('div.quality-overviews-summary tr:nth-child(1) th:nth-child(9)', :text => 'Downstream loxP site fails')
        assert page.has_css?('div.quality-overviews-summary tr:nth-child(1) th:nth-child(10)', :text => 'No additional vector insertions fails')

        assert page.has_css?('div.quality-overviews-summary tr:nth-child(2) td:nth-child(1)', :text => 'Legacy')
        assert page.has_css?('div.quality-overviews-summary tr:nth-child(2) td:nth-child(2)', :text => 'EUCOMM-EUMODIC')
        assert page.has_css?('div.quality-overviews-summary tr:nth-child(2) td:nth-child(3)', :text => 'UCD')
        assert page.has_css?('div.quality-overviews-summary tr:nth-child(2) td:nth-child(4)', :text => '2')
        assert page.has_css?('div.quality-overviews-summary tr:nth-child(2) td:nth-child(5)', :text => '0')
        assert page.has_css?('div.quality-overviews-summary tr:nth-child(2) td:nth-child(6)', :text => '0.0')
        assert page.has_css?('div.quality-overviews-summary tr:nth-child(2) td:nth-child(7)', :text => '2')
        assert page.has_css?('div.quality-overviews-summary tr:nth-child(2) td:nth-child(8)', :text => '1')
        assert page.has_css?('div.quality-overviews-summary tr:nth-child(2) td:nth-child(9)', :text => '2')
        assert page.has_css?('div.quality-overviews-summary tr:nth-child(2) td:nth-child(10)', :text => '1')

        assert page.has_css?('div.quality-overviews-summary tr:nth-child(3) td:nth-child(1)', :text => 'Legacy')
        assert page.has_css?('div.quality-overviews-summary tr:nth-child(3) td:nth-child(2)', :text => 'EUCOMM-EUMODIC')
        assert page.has_css?('div.quality-overviews-summary tr:nth-child(3) td:nth-child(3)', :text => 'WTSI')
        assert page.has_css?('div.quality-overviews-summary tr:nth-child(3) td:nth-child(4)', :text => '1')
        assert page.has_css?('div.quality-overviews-summary tr:nth-child(3) td:nth-child(5)', :text => '1')
        assert page.has_css?('div.quality-overviews-summary tr:nth-child(3) td:nth-child(6)', :text => '100.0')
        assert page.has_css?('div.quality-overviews-summary tr:nth-child(3) td:nth-child(7)', :text => '0')
        assert page.has_css?('div.quality-overviews-summary tr:nth-child(3) td:nth-child(8)', :text => '0')
        assert page.has_css?('div.quality-overviews-summary tr:nth-child(3) td:nth-child(9)', :text => '0')
        assert page.has_css?('div.quality-overviews-summary tr:nth-child(3) td:nth-child(10)', :text => '0')

      end

    end

  end
end
