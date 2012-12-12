# encoding: utf-8

require 'test_helper'

class QualityOverviewTest < ActiveSupport::TestCase

  setup do
    #row 1
    gene_tpi1 = Factory.create :gene, :marker_symbol => 'Tpi1', :mgi_accession_id => 'MGI:98797', :ikmc_projects_count => 3, :conditional_es_cells_count => 11,
            :non_conditional_es_cells_count => 8, :deletion_es_cells_count => 6, :other_targeted_mice_count => nil, :other_condtional_mice_count => nil, :mutation_published_as_lethal_count => nil,
            :publications_for_gene_count => nil, :go_annotations_for_gene_count => nil

    pipeline = Pipeline.find_by_name! 'EUCOMM'
    es_cell_tpi1 = Factory.create :es_cell, :name => 'EPD0183_4_A09', :allele_symbol_superscript_template => 'tm1@(EUCOMM)Wtsi', :allele_type => 'a', :pipeline => pipeline,
            :gene => gene_tpi1, :parental_cell_line => 'JM8.N4', :mutation_subtype => "conditional_ready"

    centre = Centre.find_by_name! 'CNB'
    mi_attempt_distribution_centre = Factory.create :mi_attempt_distribution_centre, :centre => centre, :is_distributed_by_emma => true
    plan = TestDummy.mi_plan 'EUCOMM-EUMODIC', 'WTSI', 'Tpi1', :force_assignment => true
    mi_attempt_tpi1 = Factory.create :mi_attempt2_status_gtc, :es_cell => es_cell_tpi1, :colony_name => 'MCFC', :mi_plan => plan,
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
    plan = TestDummy.mi_plan 'EUCOMM-EUMODIC', 'UCD', 'Celsr3', :force_assignment => true
    mi_attempt_celsr3 = Factory.create :mi_attempt2_status_gtc, :es_cell => es_cell_celsr3, :colony_name => 'UCD-10009A-F9-1',
            :mi_plan => plan, :number_of_het_offspring => 2

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
    plan = TestDummy.mi_plan 'EUCOMM-EUMODIC', 'UCD', 'Lgi2', :force_assignment => true
    mi_attempt_lgi2 = Factory.create :mi_attempt2_status_gtc, :es_cell => es_cell_lgi2, :colony_name => 'BL1071',
            :mi_plan => plan, :number_of_het_offspring => 2

    mi_attempt_lgi2.distribution_centres.push(mi_attempt_distribution_centre)
    mi_attempt_lgi2.save!
  end

  should 'accept the following attributes' do

    quality_overview_grouping = QualityOverviewGrouping.new
    quality_overview_grouping.consortium = 'EUCOMM-EUMODIC'
    quality_overview_grouping.production_centre = 'UCD'
    quality_overview_grouping.quality_overviews = ''
    quality_overview_grouping.number_of_genotype_confirmed_colonies = '2'
    quality_overview_grouping.colonies_with_overall_pass = '0'
    quality_overview_grouping.percentage_pass = '0.0'
    quality_overview_grouping.confirm_locus_targeted_total = '1'
    quality_overview_grouping.confirm_structure_targeted_allele_total = '0'
    quality_overview_grouping.confirm_downstream_lox_p_site_total = '1'
    quality_overview_grouping.confirm_no_additional_vector_insertions_total = '0'

    assert quality_overview_grouping.instance_variables.include?(:@consortium)
    assert quality_overview_grouping.instance_variables.include?(:@production_centre)
    assert quality_overview_grouping.instance_variables.include?(:@quality_overviews)
    assert quality_overview_grouping.instance_variables.include?(:@number_of_genotype_confirmed_colonies)
    assert quality_overview_grouping.instance_variables.include?(:@colonies_with_overall_pass)
    assert quality_overview_grouping.instance_variables.include?(:@percentage_pass)
    assert quality_overview_grouping.instance_variables.include?(:@confirm_locus_targeted_total)
    assert quality_overview_grouping.instance_variables.include?(:@confirm_structure_targeted_allele_total)
    assert quality_overview_grouping.instance_variables.include?(:@confirm_downstream_lox_p_site_total)
    assert quality_overview_grouping.instance_variables.include?(:@confirm_no_additional_vector_insertions_total)

    assert_equal 'EUCOMM-EUMODIC', quality_overview_grouping.consortium
    assert_equal 'UCD', quality_overview_grouping.production_centre
    assert_equal '2', quality_overview_grouping.number_of_genotype_confirmed_colonies
    assert_equal '0', quality_overview_grouping.colonies_with_overall_pass
    assert_equal '0.0', quality_overview_grouping.percentage_pass
    assert_equal '1', quality_overview_grouping.confirm_locus_targeted_total
    assert_equal '0', quality_overview_grouping.confirm_structure_targeted_allele_total
    assert_equal '1', quality_overview_grouping.confirm_downstream_lox_p_site_total
    assert_equal '0', quality_overview_grouping.confirm_no_additional_vector_insertions_total

  end

  should 'initialise with correct default values' do
    quality_overview_grouping = QualityOverviewGrouping.new
    assert_equal 0, quality_overview_grouping.confirm_locus_targeted_total
    assert_equal 0, quality_overview_grouping.confirm_structure_targeted_allele_total
    assert_equal 0, quality_overview_grouping.confirm_downstream_lox_p_site_total
    assert_equal 0, quality_overview_grouping.confirm_no_additional_vector_insertions_total
    assert_equal 0, quality_overview_grouping.colonies_with_overall_pass
    assert_equal 0, quality_overview_grouping.percentage_pass
  end

  should '#calculate_percentage_pass' do
    quality_overview_grouping = QualityOverviewGrouping.new
    quality_overview_grouping.colonies_with_overall_pass = 4
    quality_overview_grouping.number_of_genotype_confirmed_colonies = 9
    assert_equal 44.44, quality_overview_grouping.calculate_percentage_pass
  end

end
