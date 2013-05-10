# encoding: utf-8

require 'test_helper'

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
        assert_equal "2 Knockout First, Tm1a<br/>10 Targeted Trap<br/>5 Deletion", gene.pretty_print_types_of_cells_available
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

      Factory.create :mi_attempt2,
              :es_cell => Factory.create(:es_cell, :allele => @allele),
              :mi_plan => TestDummy.mi_plan('MARC', 'MARC', :gene => @gene, :force_assignment => true),
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

      @marc_attempt = Factory.create :mi_attempt2,
              :es_cell => Factory.create(:es_cell, :allele => @allele),
              :mi_plan => TestDummy.mi_plan('MARC', 'MARC', :gene => @gene, :force_assignment => true),
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
        plan = TestDummy.mi_plan('MGP', 'WTSI', :gene => gene, :force_assignment => true)

        Factory.create :mi_attempt2,
                :es_cell => Factory.create(:es_cell, :allele => allele),
                :mi_plan => plan,
                :is_active => true

        Factory.create :mi_attempt2_status_chr,
                :es_cell => Factory.create(:es_cell, :allele => allele),
                :mi_plan => plan,
                :is_active => true

        Factory.create :mi_attempt2_status_gtc,
                :es_cell => Factory.create(:es_cell, :allele => allele),
                :mi_plan => plan

        dtcc_ucd_plan = TestDummy.mi_plan 'DTCC', 'UCD', :gene => gene, :force_assignment => true

        3.times do
          Factory.create :mi_attempt2,
                  :es_cell => Factory.create(:es_cell, :allele => allele),
                  :mi_plan => dtcc_ucd_plan,
                  :is_active => true
        end

        Factory.create :mi_attempt2_status_gtc,
                :es_cell => Factory.create(:es_cell, :allele => allele),
                :mi_plan => dtcc_ucd_plan

        marc_plan = TestDummy.mi_plan 'MARC', 'MARC', :gene => gene, :force_assignment => true
        Factory.create :mi_attempt2,
                :es_cell => Factory.create(:es_cell, :allele => allele),
                :mi_plan => marc_plan,
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
        plan = TestDummy.mi_plan('MGP', 'WTSI', :gene => gene, :force_assignment => true)
        2.times do
          mi = Factory.create :mi_attempt2_status_gtc,
                  :es_cell => Factory.create(:es_cell, :allele => allele),
                  :mi_plan => plan,
                  :is_active => true
          assert_equal MiAttempt::Status.genotype_confirmed.name, mi.status.name
        end

        plan = TestDummy.mi_plan('DTCC', 'UCD', :gene => gene, :force_assignment => true)
        3.times do
          mi = Factory.create :mi_attempt2_status_gtc,
                  :es_cell => Factory.create(:es_cell, :allele => allele),
                  :mi_plan => plan,
                  :is_active => true
          assert_equal MiAttempt::Status.genotype_confirmed.name, mi.status.name
        end

        plan = TestDummy.mi_plan('MARC', 'MARC', :gene => gene, :force_assignment => true)
        Factory.create :mi_attempt2,
                :es_cell => Factory.create(:es_cell, :allele => allele),
                :mi_plan => plan,
                :is_active => false

        plan = TestDummy.mi_plan('EUCOMM-EUMODIC', 'WTSI', :gene => gene, :force_assignment => true)
        in_progress_mi = Factory.create :mi_attempt2_status_gtc,
                :es_cell => Factory.create(:es_cell, :allele => allele),
                :mi_plan => plan

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
        plan = TestDummy.mi_plan('DTCC', 'UCD', :gene => gene, :force_assignment => true)
        3.times do
          mi = Factory.create :mi_attempt2_status_gtc,
                  :es_cell => Factory.create(:es_cell, :allele => allele),
                  :mi_plan => plan,
                  :is_active => true
          assert_equal MiAttempt::Status.genotype_confirmed.name, mi.status.name
        end

        plan = TestDummy.mi_plan('MGP', 'WTSI', :gene => gene, :force_assignment => true)
        2.times do
          Factory.create :mi_attempt2,
                  :es_cell => Factory.create(:es_cell, :allele => allele),
                  :mi_plan => plan,
                  :is_active => false
        end

        plan = TestDummy.mi_plan('MARC', 'MARC', :gene => gene, :force_assignment => true)
        Factory.create :mi_attempt2,
                :es_cell => Factory.create(:es_cell, :allele => allele),
                :mi_plan => plan,
                :is_active => false

        plan = TestDummy.mi_plan('EUCOMM-EUMODIC', 'ICS', :gene => gene, :force_assignment => true)
        in_progress_mi = Factory.create :mi_attempt2_status_gtc,
                :es_cell => Factory.create(:es_cell, :allele => allele),
                :mi_plan => plan
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

        plan = TestDummy.mi_plan('MGP', 'WTSI', :gene => gene, :force_assignment => true)
        mi = Factory.create :mi_attempt2_status_gtc,
                :es_cell => Factory.create(:es_cell, :allele => allele),
                :mi_plan => plan,
                :is_active => true
        pa = Factory.create :phenotype_attempt_status_pdc, :mi_attempt => mi
        assert_equal MiAttempt::Status.genotype_confirmed.name, mi.status.name

        mi = Factory.create :mi_attempt2_status_gtc,
                :es_cell => Factory.create(:es_cell, :allele => allele),
                :mi_plan => plan,
                :is_active => true
        assert_equal MiAttempt::Status.genotype_confirmed.name, mi.status.name

        plan = TestDummy.mi_plan('DTCC', 'UCD', :gene => gene, :force_assignment => true)
        mi = Factory.create :mi_attempt2_status_gtc,
                :es_cell => Factory.create(:es_cell, :allele => allele),
                :mi_plan => plan,
                :is_active => true
        pa = Factory.create :phenotype_attempt_status_pdc, :mi_attempt => mi
        assert_equal MiAttempt::Status.genotype_confirmed.name, mi.status.name

        plan = TestDummy.mi_plan('MARC', 'MARC', :gene => gene, :force_assignment => true)
        Factory.create :mi_attempt2,
                :es_cell => Factory.create(:es_cell, :allele => allele),
                :mi_plan => plan,
                :is_active => false

        plan = TestDummy.mi_plan('EUCOMM-EUMODIC', 'WTSI', :gene => gene, :force_assignment => true)
        in_progress_mi = Factory.create :mi_attempt2_status_gtc,
                :es_cell => Factory.create(:es_cell, :allele => allele),
                :mi_plan => plan

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
        mi = Factory.create :mi_attempt2_status_gtc,
                :mi_plan => bash_wtsi_cbx1_plan
        gene = mi.gene
        gene.reload
        assert_equal MiAttempt::Status.genotype_confirmed.name.gsub(' -', '').gsub(' ', '_').gsub('-', '').downcase, gene.relevant_status[:status]
      end

      should 'return correct status with multiple stamps for plan, microinjection and phenotype attempt' do
        mi = Factory.create :mi_attempt2_status_gtc,
                :mi_plan => bash_wtsi_cbx1_plan
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

    context '#to_extjs_relationship_tree_structure' do
      setup do
        assert cbx1

        @plan1 = TestDummy.mi_plan('Cbx1', 'BaSH', 'WTSI')
        @mi1_1 = Factory.create(:mi_attempt2_status_gtc, :mi_plan => @plan1)
        @mi1_2 = Factory.create(:mi_attempt2, :mi_plan => @plan1, :is_active => false, :colony_name => 'MI1_2')
        @pa1_1 = Factory.create(:phenotype_attempt, :mi_plan => @plan1, :mi_attempt => @mi1_1)

        @plan2 = TestDummy.mi_plan('Cbx1', 'BaSH', 'UCD')

        @plan3 = TestDummy.mi_plan('Cbx1', 'DTCC', 'UCD', :number_of_es_cells_starting_qc => 2)
        @mi3_1 = Factory.create(:mi_attempt2_status_gtc, :mi_plan => @plan3)
        @pa3_1 = Factory.create(:phenotype_attempt, :mi_plan => @plan3, :mi_attempt => @mi3_1, :colony_name => 'PA3_1')

        @plan4 = TestDummy.mi_plan('Cbx1', 'Helmholtz GMC', 'HMGU', 'MGPinterest')
      end

      should 'add data to consortia and production centres correctly' do
        data = cbx1.to_extjs_relationship_tree_structure

        consortium_data = data.find {|i| i['name'] == 'BaSH'}
        production_centre_data = consortium_data['children'].find {|i| i['name'] == 'WTSI'}

        assert_equal ['Consortium', 'Centre'], [consortium_data['type'], production_centre_data['type']]

        assert_equal ['BaSH', 'WTSI'], production_centre_data.values_at('consortium_name', 'production_centre_name')
        assert_equal 'BaSH', consortium_data['consortium_name']
      end

      should 'place MiPlans correctly' do
        data = cbx1.to_extjs_relationship_tree_structure

        plan_data = data.find {|i| i['name'] == 'Helmholtz GMC'}['children'].find {|i| i['name'] == 'HMGU'}['children'].first
        expected = {
          'name' => 'Plan',
          'type' => 'MiPlan',
          'id' => @plan4.id,
          'status' => 'Inspect - GLT Mouse',
          'consortium_name' => 'Helmholtz GMC',
          'production_centre_name' => 'HMGU',
          'sub_project_name' => @plan4.sub_project.name,
          'children' => []
        }
        assert_equal expected, plan_data
      end

      should 'place MiAttempts correctly' do
        data = cbx1.to_extjs_relationship_tree_structure

        plan = data.find {|i| i['name'] == 'BaSH'}['children'].find {|i| i['name'] == 'WTSI'}['children'].first
        assert plan.present?
        plan_children = plan['children']
        assert plan_children.present?

        mi_data = plan_children.find {|i| i['name'] == 'MI Attempt' and i['id'] == @mi1_2.id}
        expected = {
          'name' => 'MI Attempt',
          'type' => 'MiAttempt',
          'colony_name' => 'MI1_2',
          'id' => @mi1_2.id,
          'status' => 'Micro-injection aborted',
          'consortium_name' => 'BaSH',
          'production_centre_name' => 'WTSI',
          'mi_plan_id' => @mi1_2.mi_plan_id,
          'leaf' => true
        }
        assert_equal expected, mi_data
      end

      should 'place PhenotypeAttempts correctly' do
        data = cbx1.to_extjs_relationship_tree_structure

        plan = data.find {|i| i['name'] == 'DTCC'}['children'].find {|i| i['name'] == 'UCD'}['children'].first
        assert plan.present?
        plan_children = plan['children']
        assert plan_children.present?

        pa_data = plan_children.find {|i| i['name'] == 'Phenotype Attempt' and i['id'] == @pa3_1.id}
        expected = {
          'name' => 'Phenotype Attempt',
          'type' => 'PhenotypeAttempt',
          'colony_name' => 'PA3_1',
          'id' => @pa3_1.id,
          'status' => 'Phenotype Attempt Registered',
          'consortium_name' => 'DTCC',
          'production_centre_name' => 'UCD',
          'mi_plan_id' => @pa3_1.mi_plan_id,
          'leaf' => true
        }
        assert_equal expected, pa_data
      end
    end

  end
end
