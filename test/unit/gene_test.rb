# encoding: utf-8

require 'test_helper'
require 'mocha'

class GeneTest < ActiveSupport::TestCase
  context 'Gene' do

    context '(misc. tests)' do
      setup do
        Factory.create :gene
      end

      should have_many :es_cells
      should have_many :mi_plans

      should have_db_column(:marker_symbol).of_type(:string).with_options(:null => false, :limit => 75)
      should have_db_column(:mgi_accession_id).of_type(:string).with_options(:null => true, :limit => 40)

      should validate_presence_of :marker_symbol
      should validate_uniqueness_of :marker_symbol
    end

    context '::find_or_create_from_marts_by_mgi_accession_id' do
      should 'create gene from marts if it is not in the DB' do
        gene = Gene.find_or_create_from_marts_by_mgi_accession_id 'MGI:1923551'
        assert gene
        assert_equal 'Trafd1', gene.marker_symbol
      end

      should 'return gene if it is already in the DB without hitting the marts' do
        gene = Factory.create :gene,
                :marker_symbol => 'Abcd1', :mgi_accession_id => 'MGI:1234567890'
        assert_equal gene, Gene.find_or_create_from_marts_by_mgi_accession_id('MGI:1234567890')
      end

      should 'return nil if it does not exist in DB or marts' do
        assert_nil Gene.find_or_create_from_marts_by_mgi_accession_id('MGI:NONEXISTENT1')
      end

      should 'return nil if query was blank' do
        assert_nil Gene.find_or_create_from_marts_by_mgi_accession_id('')
      end
    end

    context '::sync_with_remotes' do
      setup do
        # Stub out the biomart calls
        dcc_gene_data = [
          {
            'mgi_accession_id' => 'MGI:11111',
            'marker_symbol'    => 'Moo1',
            'ikmc_project'     => 'EUCOMM',
            'ikmc_project_id'  => '12345'
          },
          {
            'mgi_accession_id' => 'MGI:11111',
            'marker_symbol'    => 'Moo1',
            'ikmc_project'     => 'EUCOMM',
            'ikmc_project_id'  => '67890'
          },
          {
            'mgi_accession_id' => 'MGI:22222',
            'marker_symbol'    => 'Quack2',
            'ikmc_project'     => 'KOMP-CSD',
            'ikmc_project_id'  => '99999'
          },
          {
            'mgi_accession_id' => 'MGI:33333',
            'marker_symbol'    => 'FuBar',
            'ikmc_project'     => 'TIGM',
            'ikmc_project_id'  => 'weeeeeee'
          }
        ]

        dcc_gene_data_plus_one_project = dcc_gene_data + [
          {
            'mgi_accession_id' => 'MGI:11111',
            'marker_symbol'    => 'Moo1',
            'ikmc_project'     => 'mirKO',
            'ikmc_project_id'  => 'newbee'
          }
        ]

        dcc_gene_data_minus_one_gene = dcc_gene_data.reject{ |elm| elm['marker_symbol'] == 'FuBar' }

        DCC_BIOMART.stubs(:search)
               .returns(dcc_gene_data)
          .then.returns(dcc_gene_data)
          .then.returns(dcc_gene_data_plus_one_project)
          .then.returns(dcc_gene_data_plus_one_project)
          .then.returns(dcc_gene_data_minus_one_gene)
          .then.returns(dcc_gene_data_minus_one_gene)

        targ_rep_clone_data = [
          {
            'mgi_accession_id' => 'MGI:11111',
            'pipeline'         => 'EUCOMM',
            'escell_clone'     => 'EPD0123_A01',
            'mutation_subtype' => 'conditional_ready'
          },
          {
            'mgi_accession_id' => 'MGI:11111',
            'pipeline'         => 'EUCOMM',
            'escell_clone'     => 'EPD0123_A02',
            'mutation_subtype' => 'conditional_ready'
          },
          {
            'mgi_accession_id' => 'MGI:11111',
            'pipeline'         => 'EUCOMM',
            'escell_clone'     => 'EPD0123_A03',
            'mutation_subtype' => 'targeted_non_conditional'
          },
          {
            'mgi_accession_id' => 'MGI:22222',
            'pipeline'         => 'KOMP-CSD',
            'escell_clone'     => 'EPD0456_A01',
            'mutation_subtype' => 'deletion'
          }
        ]

        TARG_REP_BIOMART.stubs(:search).returns(targ_rep_clone_data)
      end

      teardown do
        DCC_BIOMART.unstub(:search)
        TARG_REP_BIOMART.unstub(:search)
      end

      should 'work' do
        assert_equal 0, Gene.all.count

        Gene.sync_with_remotes
        moo1   = Gene.find_by_marker_symbol('Moo1')
        quack2 = Gene.find_by_marker_symbol('Quack2')
        fubar  = Gene.find_by_marker_symbol('FuBar')

        assert_equal 3, Gene.all.count
        assert_equal 2, moo1.ikmc_projects_count
        assert_equal 2, moo1.conditional_es_cells_count
        assert_equal 1, moo1.non_conditional_es_cells_count
        assert_equal 1, quack2.ikmc_projects_count
        assert_equal 1, quack2.deletion_es_cells_count
        assert_nil quack2.conditional_es_cells_count
        assert_nil quack2.non_conditional_es_cells_count
        assert_nil fubar.ikmc_projects_count
        assert_nil fubar.conditional_es_cells_count
        assert_nil fubar.non_conditional_es_cells_count
        assert_nil fubar.deletion_es_cells_count

        Gene.sync_with_remotes
        moo1.reload

        assert_equal 3, Gene.all.count
        assert_equal 3, moo1.ikmc_projects_count

        Gene.sync_with_remotes
        moo1.reload

        assert_equal 2, Gene.all.count
        assert_nil Gene.find_by_marker_symbol('FuBar')
        assert_equal 2, moo1.ikmc_projects_count
      end
    end

    context '#pretty_print_types_of_cells_available' do
      should 'work' do
        gene = Factory.create :gene,
                :marker_symbol => 'Moo1',
                :mgi_accession_id => 'MGI:12345',
                :conditional_es_cells_count => 2,
                :non_conditional_es_cells_count => 10,
                :deletion_es_cells_count => 5

        assert gene
        assert_equal "2 Conditional</br>10 Targeted Trap</br>5 Deletion", gene.pretty_print_types_of_cells_available
      end
    end

    context '#pretty_print_non_assigned_mi_plans' do
      should 'work' do
        gene = Factory.create :gene,
          :marker_symbol => 'Moo1',
          :mgi_accession_id => 'MGI:12345'

        Factory.create :mi_plan,
          :gene => gene,
          :consortium => Consortium.find_by_name!('BaSH'), 
          :mi_plan_status => MiPlanStatus.find_by_name!('Interest')

        Factory.create :mi_plan,
          :gene => gene,
          :consortium => Consortium.find_by_name!('MGP'),
          :production_centre => Centre.find_by_name!('WTSI'),
          :mi_plan_status => MiPlanStatus.find_by_name!('Interest')

        Factory.create :mi_attempt, :is_active => true

        assert gene
        assert_equal 2, gene.mi_plans.count
        assert_match '', gene.pretty_print_assigned_mi_plans
        assert_equal '', gene.pretty_print_mi_attempts_in_progress
        assert_equal '', gene.pretty_print_mi_attempts_genotype_confirmed
        assert_match '[BaSH:Interest]', gene.pretty_print_non_assigned_mi_plans
        assert_match '[MGP:WTSI:Interest]', gene.pretty_print_non_assigned_mi_plans
      end
    end

    context '#pretty_print_assigned_mi_plans' do
      should 'work' do
        gene = Factory.create :gene,
          :marker_symbol => 'Moo1',
          :mgi_accession_id => 'MGI:12345'

        Factory.create :mi_plan,
          :gene => gene,
          :consortium => Consortium.find_by_name!('BaSH'), 
          :mi_plan_status => MiPlanStatus.find_by_name!('Assigned')

        Factory.create :mi_plan,
          :gene => gene,
          :consortium => Consortium.find_by_name!('MGP'),
          :production_centre => Centre.find_by_name!('WTSI'),
          :mi_plan_status => MiPlanStatus.find_by_name!('Assigned')

        Factory.create :mi_attempt, :is_active => true

        assert gene
        assert_equal 2, gene.mi_plans.count
        assert_equal '', gene.pretty_print_non_assigned_mi_plans
        assert_equal '', gene.pretty_print_mi_attempts_in_progress
        assert_equal '', gene.pretty_print_mi_attempts_genotype_confirmed
        assert_match '[BaSH]', gene.pretty_print_assigned_mi_plans
        assert_match '[MGP:WTSI]', gene.pretty_print_assigned_mi_plans
      end
    end

    context '#pretty_print_mi_attempts_in_progress' do
      should 'work' do
        gene = Factory.create :gene,
          :marker_symbol => 'Moo1',
          :mgi_accession_id => 'MGI:12345'

        2.times do
          Factory.create :mi_attempt,
            :es_cell => Factory.create(:es_cell, :gene => gene),
            :consortium_name => 'MGP',
            :production_centre_name => 'WTSI',
            :is_active => true
        end

        3.times do
          Factory.create :mi_attempt,
            :es_cell => Factory.create(:es_cell, :gene => gene),
            :consortium_name => 'DTCC',
            :production_centre_name => 'UCD',
            :is_active => true
        end

        assert gene
        assert_equal 2, gene.mi_plans.count
        assert_equal '', gene.pretty_print_non_assigned_mi_plans
        assert_equal '', gene.pretty_print_assigned_mi_plans
        assert_equal '', gene.pretty_print_mi_attempts_genotype_confirmed
        assert_match '[MGP:WTSI:2]', gene.pretty_print_mi_attempts_in_progress
        assert_match '[DTCC:UCD:3]', gene.pretty_print_mi_attempts_in_progress
      end
    end

    context '#pretty_print_mi_attempts_genotype_confirmed' do
      should 'work' do
        gene = Factory.create :gene,
          :marker_symbol => 'Moo1',
          :mgi_accession_id => 'MGI:12345'

        2.times do
          Factory.create :mi_attempt,
            :es_cell => Factory.create(:es_cell, :gene => gene),
            :consortium_name => 'MGP',
            :production_centre_name => 'WTSI',
            :mi_attempt_status => MiAttemptStatus.genotype_confirmed,
            :is_active => true
        end

        3.times do
          Factory.create :mi_attempt,
            :es_cell => Factory.create(:es_cell, :gene => gene),
            :consortium_name => 'DTCC',
            :production_centre_name => 'UCD',
            :mi_attempt_status => MiAttemptStatus.genotype_confirmed,
            :is_active => true
        end

        assert gene
        assert_equal 2, gene.mi_plans.count
        assert_equal '', gene.pretty_print_non_assigned_mi_plans
        assert_equal '', gene.pretty_print_assigned_mi_plans
        assert_equal '', gene.pretty_print_mi_attempts_in_progress
        assert_match '[MGP:WTSI:2]', gene.pretty_print_mi_attempts_genotype_confirmed
        assert_match '[DTCC:UCD:3]', gene.pretty_print_mi_attempts_genotype_confirmed
      end
    end

  end
end
