# encoding: utf-8

require 'test_helper'

class QualityOverviewTest < Kermits2::IntegrationTest

  context 'QualityOverview' do

    context 'once logged in' do
      setup do
        visit '/users/logout'
        login
      end

      should 'allow users to visit the correct page & see entries' do

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

        puts mi_attempt_tpi1.pretty_print_distribution_centres == "[EMMA::CNB]"

        visit '/quality_overviews'
        assert_match '/quality_overviews', current_url

        assert page.has_css?('div.quality-overviews')

        assert page.has_css?('div.quality-overviews tr:nth-child(1) th:nth-child(1)', :text => 'Consortium')
        assert page.has_css?('div.quality-overviews tr:nth-child(1) th:nth-child(2)', :text => 'Production centre')
        assert page.has_css?('div.quality-overviews tr:nth-child(1) th:nth-child(3)', :text => 'Distribution centres')
        assert page.has_css?('div.quality-overviews tr:nth-child(1) th:nth-child(4)', :text => 'Marker symbol')
        assert page.has_css?('div.quality-overviews tr:nth-child(1) th:nth-child(5)', :text => 'ES cell clone')
        assert page.has_css?('div.quality-overviews tr:nth-child(1) th:nth-child(6)', :text => 'Colony')
        assert page.has_css?('div.quality-overviews tr:nth-child(1) th:nth-child(7)', :text => 'Status')
        assert page.has_css?('div.quality-overviews tr:nth-child(1) th:nth-child(8)', :text => 'Overall pass')
        assert page.has_css?('div.quality-overviews tr:nth-child(1) th:nth-child(9)', :text => 'Locus targeted')
        assert page.has_css?('div.quality-overviews tr:nth-child(1) th:nth-child(10)', :text => 'Structure targeted')
        assert page.has_css?('div.quality-overviews tr:nth-child(1) th:nth-child(11)', :text => 'Downstream LoxP site')
        assert page.has_css?('div.quality-overviews tr:nth-child(1) th:nth-child(12)', :text => 'No additional vector insertions')
        assert page.has_css?('div.quality-overviews tr:nth-child(1) th:nth-child(13)', :text => 'ES-dist-qc')
        assert page.has_css?('div.quality-overviews tr:nth-child(1) th:nth-child(14)', :text => 'ES-user-qc')
        assert page.has_css?('div.quality-overviews tr:nth-child(1) th:nth-child(15)', :text => 'Mouse-qc')

        assert page.has_css?('div.quality-overviews tr:nth-child(2) td:nth-child(1)', :text => 'EUCOMM-EUMODIC')
        assert page.has_css?('div.quality-overviews tr:nth-child(2) td:nth-child(2)', :text => 'WTSI')
        assert page.has_css?('div.quality-overviews tr:nth-child(2) td:nth-child(3)')
        assert page.has_css?('div.quality-overviews tr:nth-child(2) td:nth-child(4)', :text => 'Tpi1')
        assert page.has_css?('div.quality-overviews tr:nth-child(2) td:nth-child(5)', :text => 'EPD0183_4_A09')
        assert page.has_css?('div.quality-overviews tr:nth-child(2) td:nth-child(6)', :text => 'MCFC')
        assert page.has_css?('div.quality-overviews tr:nth-child(2) td:nth-child(7)', :text => 'Genotype confirmed')
        assert page.has_css?('div.quality-overviews tr:nth-child(2) td:nth-child(8)', :text => 'true')
        assert page.has_css?('div.quality-overviews tr:nth-child(2) td:nth-child(9)', :text => '1')
        assert page.has_css?('div.quality-overviews tr:nth-child(2) td:nth-child(10)', :text => '1')
        assert page.has_css?('div.quality-overviews tr:nth-child(2) td:nth-child(11)', :text => '1')
        assert page.has_css?('div.quality-overviews tr:nth-child(2) td:nth-child(12)', :text => '1')
        assert page.has_css?('div.quality-overviews tr:nth-child(2) td:nth-child(13)', :text => '')
        assert page.has_css?('div.quality-overviews tr:nth-child(2) td:nth-child(14)', :text => '')
        assert page.has_css?('div.quality-overviews tr:nth-child(2) td:nth-child(15)', :text => 'qc_lacz_sr_pcr qc_loa_qpcr qc_loxp_confirmation qc_mutant_specific_sr_pcr qc_neo_count_qpcr qc_tv_backbone_assay')

      end

    end

  end
end
