# encoding: utf-8

require 'test_helper'
require 'mocha'

class GeneTest < ActiveSupport::TestCase
  context 'Gene' do

    should 'have attibutes' do
      Factory.create :gene
      create_common_test_objects

      assert_should have_many :allele
      assert_should have_many :mi_plans

      assert_should have_db_column(:marker_symbol).of_type(:string).with_options(:null => false, :limit => 75)
      assert_should have_db_column(:mgi_accession_id).of_type(:string).with_options(:null => true, :limit => 40)

      assert_should validate_presence_of :marker_symbol
      assert_should validate_uniqueness_of :marker_symbol
    end

    should 'not output private attributes in serialization' do
      Factory.create :gene
      gene_json = Gene.first.as_json.stringify_keys

      assert_false gene_json.keys.include? 'created_at'
      assert_false gene_json.keys.include? 'updated_at'
      assert_false gene_json.keys.include? 'updated_by'
    end

    should 'include pretty_print type methods in serialization' do
      Factory.create :gene
      gene_json = Gene.first.as_json.stringify_keys

      assert gene_json.keys.include? 'pretty_print_types_of_cells_available'
      assert gene_json.keys.include? 'non_assigned_mi_plans'
      assert gene_json.keys.include? 'assigned_mi_plans'
      assert gene_json.keys.include? 'pretty_print_mi_attempts_in_progress'
      assert gene_json.keys.include? 'pretty_print_mi_attempts_genotype_confirmed'
      assert gene_json.keys.include? 'pretty_print_aborted_mi_attempts'
      assert gene_json.keys.include? 'pretty_print_phenotype_attempts'
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
        assert_equal "2 Conditional<br/>10 Targeted Trap<br/>5 Deletion", gene.pretty_print_types_of_cells_available
      end
    end

    def setup_for_non_assigned_mi_plans_tests
      @gene = Factory.create :gene_cbx1
      @allele = Factory.create :allele, :gene => @gene

      Factory.create :mi_plan, :gene => @gene

      @mgp_plan = Factory.create :mi_plan,
              :gene => @gene,
              :consortium => Consortium.find_by_name!('MGP'),
              :production_centre => Centre.find_by_name!('WTSI')
      assert_equal 'Inspect - Conflict', @mgp_plan.status.name

      Factory.create :mi_plan,
              :gene => @gene,
              :consortium => Consortium.find_by_name!('MRC'),
              :production_centre => Centre.find_by_name!('MRC - Harwell'),
              :is_active => false

      Factory.create :mi_plan,
              :gene => @gene,
              :consortium => Consortium.find_by_name!('EUCOMM-EUMODIC'),
              :production_centre => Centre.find_by_name!('WTSI'),
              :number_of_es_cells_starting_qc => 4

      Factory.create :mi_attempt,
              :es_cell => Factory.create(:es_cell, :allele => @allele),
              :consortium_name => 'MARC',
              :production_centre_name => 'MARC',
              :is_active => true
    end

    context '#non_assigned_mi_plans' do
      should 'work' do
        setup_for_non_assigned_mi_plans_tests

        assert @gene
        assert_equal 5, @gene.mi_plans.count
        mi_plans = @gene.non_assigned_mi_plans
        assert mi_plans.include?({ :id => @mgp_plan.id, :consortium => 'MGP', :production_centre => 'WTSI', :status_name => 'Inspect - Conflict' })

        statuses = mi_plans.map {|p| p[:status_name]}
        assert !statuses.blank?
        assert_not_include statuses, 'Assigned'
        assert_not_include statuses, 'Inactive'
        assert_not_include statuses, 'Assigned - ES Cell QC In Progress'
      end
    end

    context '#pretty_print_non_assigned_mi_plans' do
      should 'work' do
        setup_for_non_assigned_mi_plans_tests

        assert @gene
        assert_equal 5, @gene.mi_plans.count
        result = @gene.pretty_print_non_assigned_mi_plans
        assert_include result, '[MGP:WTSI:Inspect - Conflict]'
        assert_not_include result, '[MRC:MRC - Harwell:Inactive]'
        assert_not_include result, '[MARC:MARC:Assigned]'
        assert_not_include result, '[EUCOMM-EUMODIC:WTSI:Assigned - ES Cell QC In Progress]'
      end
    end

    def setup_for_assigned_mi_plans_tests
      @gene = Factory.create :gene_cbx1
      @allele = Factory.create :allele, :gene => @gene

      @bash_plan = Factory.create :mi_plan,
              :gene => @gene,
              :consortium => Consortium.find_by_name!('BaSH'),
              :status => MiPlan::Status.find_by_name!('Assigned')

      @mgp_plan = Factory.create :mi_plan,
              :gene => @gene,
              :consortium => Consortium.find_by_name!('MGP'),
              :production_centre => Centre.find_by_name!('WTSI'),
              :number_of_es_cells_starting_qc => 5

      @jax_plan = Factory.create :mi_plan,
              :gene => @gene,
              :consortium => Consortium.find_by_name!('JAX'),
              :production_centre => Centre.find_by_name!('JAX'),
              :number_of_es_cells_passing_qc => 7

      @marc_attempt = Factory.create :mi_attempt,
              :es_cell => Factory.create(:es_cell, :allele => @allele),
              :consortium_name => 'MARC',
              :production_centre_name => 'MARC',
              :is_active => true
    end

    context '#assigned_mi_plans' do
      should 'work' do
        setup_for_assigned_mi_plans_tests

        assert @gene
        assert_equal 4, @gene.mi_plans.count
        result = @gene.assigned_mi_plans
        assert_include result, { :id => @bash_plan.id, :consortium => 'BaSH', :production_centre => nil }
        assert_include result, { :id => @mgp_plan.id, :consortium => 'MGP', :production_centre => 'WTSI' }
        assert_include result, { :id => @jax_plan.id, :consortium => 'JAX', :production_centre => 'JAX' }
        assert_not_include result, { :id => @marc_attempt.mi_plan.id, :consortium => 'MARC', :production_centre => 'MARC' }
      end
    end

    context '#pretty_print_assigned_mi_plans' do
      should 'work' do
        setup_for_assigned_mi_plans_tests

        assert_equal 4, @gene.mi_plans.count
        result = @gene.pretty_print_assigned_mi_plans
        assert_include result, '[BaSH]'
        assert_include result, '[MGP:WTSI]'
        assert_include result, '[JAX:JAX]'
        assert_not_include result, '[MARC:MARC]'
      end
    end

    context '#pretty_print_mi_attempts_in_progress' do
      should 'work' do
        gene = Factory.create :gene,
                :marker_symbol => 'Moo1',
                :mgi_accession_id => 'MGI:12345'

        allele = Factory.create :allele, :gene => gene

        Factory.create :mi_attempt,
                :es_cell => Factory.create(:es_cell, :allele => allele),
                :consortium_name => 'MGP',
                :production_centre_name => 'WTSI',
                :is_active => true

        Factory.create :mi_attempt_chimeras_obtained,
                :es_cell => Factory.create(:es_cell, :allele => allele),
                :consortium_name => 'MGP',
                :production_centre_name => 'WTSI',
                :is_active => true

        Factory.create :wtsi_mi_attempt_genotype_confirmed,
                :es_cell => Factory.create(:es_cell, :allele => allele),
                :consortium_name => 'MGP',
                :production_centre_name => 'WTSI'

        3.times do
          Factory.create :mi_attempt,
                  :es_cell => Factory.create(:es_cell, :allele => allele),
                  :consortium_name => 'DTCC',
                  :production_centre_name => 'UCD',
                  :is_active => true
        end

        Factory.create :mi_attempt_genotype_confirmed,
                :es_cell => Factory.create(:es_cell, :allele => allele),
                :consortium_name => 'DTCC',
                :production_centre_name => 'UCD'

        Factory.create :mi_attempt,
                :es_cell => Factory.create(:es_cell, :allele => allele),
                :consortium_name => 'MARC',
                :production_centre_name => 'MARC',
                :is_active => false

        assert gene
        assert_equal 3, gene.mi_plans.count
        result = gene.pretty_print_mi_attempts_in_progress
        assert_match '[MGP:WTSI:2]', result
        assert_match '[DTCC:UCD:3]', result
        assert_false result.include?('[MARC:MARC:1]')
      end
    end

    context '#pretty_print_mi_attempts_genotype_confirmed' do
      should 'work' do
        gene = Factory.create :gene,
                :marker_symbol => 'Moo1',
                :mgi_accession_id => 'MGI:12345'

        allele = Factory.create :allele, :gene => gene

        2.times do
          mi = Factory.create :wtsi_mi_attempt_genotype_confirmed,
                  :es_cell => Factory.create(:es_cell, :allele => allele),
                  :consortium_name => 'MGP',
                  :is_active => true
          assert_equal MiAttempt::Status.genotype_confirmed.name, mi.status.name
        end

        3.times do
          mi = Factory.create :mi_attempt_genotype_confirmed,
                  :es_cell => Factory.create(:es_cell, :allele => allele),
                  :consortium_name => 'DTCC',
                  :production_centre_name => 'UCD',
                  :is_active => true
          assert_equal MiAttempt::Status.genotype_confirmed.name, mi.status.name
        end

        Factory.create :mi_attempt,
                :es_cell => Factory.create(:es_cell, :allele => allele),
                :consortium_name => 'MARC',
                :production_centre_name => 'MARC',
                :is_active => false

        in_progress_mi = Factory.create :mi_attempt_genotype_confirmed,
                :es_cell => Factory.create(:es_cell, :allele => allele),
                :consortium_name => 'EUCOMM-EUMODIC',
                :production_centre_name => 'WTSI'
        in_progress_mi.number_of_het_offspring = 0
        in_progress_mi.total_male_chimeras = 0
        in_progress_mi.save!
        assert_equal MiAttempt::Status.micro_injection_in_progress.name, in_progress_mi.status.name

        assert gene
        assert_equal 4, gene.mi_plans.count

        result = gene.pretty_print_mi_attempts_genotype_confirmed
        assert_match '[MGP:WTSI:2]', result
        assert_match '[DTCC:UCD:3]', result
        assert_false result.include?('[MARC:MARC:1]')
        assert_false result.include?('[EUCOMM-EUMODIC:WTSI:1]')
      end
    end

    context '#pretty_print_aborted_mi_attempts' do
      should 'work' do
        gene = Factory.create :gene,
                :marker_symbol => 'Moo1',
                :mgi_accession_id => 'MGI:12345'

        allele = Factory.create :allele, :gene => gene

        3.times do
          mi = Factory.create :mi_attempt_genotype_confirmed,
                  :es_cell => Factory.create(:es_cell, :allele => allele),
                  :consortium_name => 'DTCC',
                  :production_centre_name => 'UCD',
                  :is_active => true
          assert_equal MiAttempt::Status.genotype_confirmed.name, mi.status.name
        end

        2.times do
          Factory.create :mi_attempt,
                  :es_cell => Factory.create(:es_cell, :allele => allele),
                  :consortium_name => 'MGP',
                  :production_centre_name => 'WTSI',
                  :is_active => false
        end

        Factory.create :mi_attempt,
                :es_cell => Factory.create(:es_cell, :allele => allele),
                :consortium_name => 'MARC',
                :production_centre_name => 'MARC',
                :is_active => false

        in_progress_mi = Factory.create :wtsi_mi_attempt_genotype_confirmed,
                :es_cell => Factory.create(:es_cell, :allele => allele),
                :consortium_name => 'EUCOMM-EUMODIC'
        in_progress_mi.update_attributes!(:is_released_from_genotyping => false,
          :total_male_chimeras => 0)
        assert_equal MiAttempt::Status.micro_injection_in_progress.name, in_progress_mi.status.name

        assert gene
        assert_equal 4, gene.mi_plans.count
        result = gene.pretty_print_aborted_mi_attempts
        assert_match '[MGP:WTSI:2]', result
        assert_match '[MARC:MARC:1]', result
        assert_false result.include?('[DTCC:UCD:3]')
        assert_false result.include?('[EUCOMM-EUMODIC:WTSI:1]')
      end
    end

    context '#pretty_print_phenotype_attempts' do
      should 'work' do
        gene = Factory.create :gene,
                :marker_symbol => 'Moo1',
                :mgi_accession_id => 'MGI:12345'

        allele = Factory.create :allele, :gene => gene

        mi = Factory.create :wtsi_mi_attempt_genotype_confirmed,
                :es_cell => Factory.create(:es_cell, :allele => allele),
                :consortium_name => 'MGP',
                :is_active => true
        pa = Factory.create :phenotype_attempt_status_pdc, :mi_attempt => mi
        assert_equal MiAttempt::Status.genotype_confirmed.name, mi.status.name

        mi = Factory.create :wtsi_mi_attempt_genotype_confirmed,
                :es_cell => Factory.create(:es_cell, :allele => allele),
                :consortium_name => 'MGP',
                :is_active => true
        assert_equal MiAttempt::Status.genotype_confirmed.name, mi.status.name

        mi = Factory.create :mi_attempt_genotype_confirmed,
                :es_cell => Factory.create(:es_cell, :allele => allele),
                :consortium_name => 'DTCC',
                :production_centre_name => 'UCD',
                :is_active => true
        pa = Factory.create :phenotype_attempt_status_pdc, :mi_attempt => mi
        assert_equal MiAttempt::Status.genotype_confirmed.name, mi.status.name

        Factory.create :mi_attempt,
                :es_cell => Factory.create(:es_cell, :allele => allele),
                :consortium_name => 'MARC',
                :production_centre_name => 'MARC',
                :is_active => false

        in_progress_mi = Factory.create :mi_attempt_genotype_confirmed,
                :es_cell => Factory.create(:es_cell, :allele => allele),
                :consortium_name => 'EUCOMM-EUMODIC',
                :production_centre_name => 'WTSI'
        in_progress_mi.number_of_het_offspring = 0
        in_progress_mi.total_male_chimeras = 0
        in_progress_mi.save!
        assert_equal MiAttempt::Status.micro_injection_in_progress.name, in_progress_mi.status.name

        assert gene
        assert_equal 4, gene.mi_plans.count
        assert_equal 2, gene.phenotype_attempts.count
        result = gene.pretty_print_phenotype_attempts
        assert_match '[DTCC:UCD:1]', result
        assert_match '[MGP:WTSI:1]', result
      end
    end

    context '#relevant_status' do
      should 'return correct status with only plan' do
        plan = Factory.create :mi_plan
        gene = plan.gene
        assert_equal MiPlan::Status["Assigned"].name.gsub(' -', '').gsub(' ', '_').gsub('-', '').downcase, gene.relevant_status[:status]
      end

      should 'return correct status with plan and microinjection attempt' do
        mi = Factory.create :wtsi_mi_attempt_genotype_confirmed,
                :consortium_name => 'BaSH',
                :production_centre_name => 'WTSI'
        gene = mi.gene
        gene.reload
        assert_equal MiAttempt::Status.genotype_confirmed.name.gsub(' -', '').gsub(' ', '_').gsub('-', '').downcase, gene.relevant_status[:status]
      end

      should 'return correct status with multiple stamps for plan, microinjection and phenotype attempt' do

        mi = Factory.create :wtsi_mi_attempt_genotype_confirmed,
                :consortium_name => 'BaSH',
                :production_centre_name => 'WTSI'
        plan = mi.mi_plan
        plan.update_attributes!(:number_of_es_cells_starting_qc => 1)
        pt = Factory.create :phenotype_attempt, :mi_plan => plan, :mi_attempt => mi
        gene = plan.gene
        replace_status_stamps(plan,
          'Assigned' => '2011-01-01',
          'Assigned - ES Cell QC In Progress' => '2011-05-31')

        replace_status_stamps(mi,
          'Micro-injection in progress' => '2011-05-31',
          'Genotype confirmed' => '2011-05-31')

        replace_status_stamps(pt,
          'Phenotype Attempt Registered' => '2011-05-31')

        gene.reload
        assert_equal PhenotypeAttempt::Status["Phenotype Attempt Registered"].name.gsub(' -', '').gsub(' ', '_').gsub('-', '').downcase, gene.relevant_status[:status]
      end

      should 'have #es_cells_count' do
        gene = Factory.create :gene, :conditional_es_cells_count => 2,
                :non_conditional_es_cells_count => 3,
                :deletion_es_cells_count => 4
        assert_equal 9, gene.es_cells_count

        gene = Factory.create :gene
        assert_equal 0, gene.es_cells_count
      end

    end
  end
end
