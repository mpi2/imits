require 'test_helper'

class QualityOverviewsControllerTest < ActionController::TestCase
  context 'QualityOverviewsController' do
    setup do
      #row 1
      gene_tpi1 = Factory.create :gene, :marker_symbol => 'Tpi1', :mgi_accession_id => 'MGI:98797', :ikmc_projects_count => 3, :conditional_es_cells_count => 11,
        :non_conditional_es_cells_count => 8, :deletion_es_cells_count => 6, :other_targeted_mice_count => nil, :other_condtional_mice_count => nil, :mutation_published_as_lethal_count => nil,
        :publications_for_gene_count => nil, :go_annotations_for_gene_count => nil

      allele_with_gene_tpi1 = Factory.create(:allele, :gene => gene_tpi1)
      
      pipeline = TargRep::Pipeline.find_by_name! 'EUCOMM'
      es_cell_tpi1 = Factory.create :es_cell, :name => 'EPD0183_4_A09', :allele_symbol_superscript_template => 'tm1@(EUCOMM)Wtsi', :allele_type => 'a', :pipeline => pipeline,
        :allele => allele_with_gene_tpi1, :parental_cell_line => 'JM8.N4', :mutation_subtype => "conditional_ready"

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
      
      allele_with_gene_celsr3 = Factory.create(:allele, :gene => gene_celsr3)

      pipeline = TargRep::Pipeline.find_by_name! 'KOMP-Regeneron'
      es_cell_celsr3 = Factory.create :es_cell, :name => '10009A-F9', :allele_symbol_superscript_template => 'tm1(KOMP)Vlcg', :allele_type => nil, :pipeline => pipeline,
        :allele => allele_with_gene_celsr3, :parental_cell_line => 'VGB6', :mutation_subtype => 'deletion'

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

      allele_with_gene_lgi2 = Factory.create(:allele, :gene => gene_lgi2)

      pipeline = TargRep::Pipeline.find_by_name! 'KOMP-Regeneron'
      es_cell_lgi2 = Factory.create :es_cell, :name => '10011B-G3', :allele_symbol_superscript_template => 'tm1(KOMP)Vlcg', :allele_type => nil, :pipeline => pipeline,
        :allele => allele_with_gene_lgi2, :parental_cell_line => 'VGB6', :mutation_subtype => 'deletion'

      centre = Centre.find_by_name! 'UCD'
      mi_attempt_distribution_centre = Factory.create :mi_attempt_distribution_centre, :centre => centre, :is_distributed_by_emma => true
      plan = TestDummy.mi_plan 'EUCOMM-EUMODIC', 'UCD', 'Lgi2', :force_assignment => true
      mi_attempt_lgi2 = Factory.create :mi_attempt2_status_gtc, :es_cell => es_cell_lgi2, :colony_name => 'BL1071',
              :mi_plan => plan, :number_of_het_offspring => 2

      mi_attempt_lgi2.distribution_centres.push(mi_attempt_distribution_centre)
      mi_attempt_lgi2.save!
    end

    should 'require authentication' do
      get :index
      assert !response.success?
      assert_redirected_to new_user_session_path
    end

    should 'GET quality overviews as CSV' do

      sign_in default_user

      quality_overviews = QualityOverview.import(ALLELE_OVERALL_PASS_PATH)
      @quality_overviews = QualityOverview.sort(quality_overviews)
      header_row = @quality_overviews.first.column_names

      csv = CSV.generate(:force_quotes => true) do |line|
        line << header_row
        @quality_overviews.each do |quality_overview|
          line << quality_overview.column_values.flatten
        end
      end
      get :export_to_csv, :format => :csv
      assert_equal response.body, csv

    end

  end
end

