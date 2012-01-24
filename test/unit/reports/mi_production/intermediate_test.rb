# encoding: utf-8

require 'test_helper'

class Reports::MiProduction::IntermediateTest < ActiveSupport::TestCase
  context 'Reports::MiProduction::Intermediate' do

    setup do
      @cbx1 = Factory.create :gene_cbx1
    end

    context 'general tests' do
      setup do
        Factory.create :mi_plan,
                :consortium => Consortium.find_by_name!('BaSH'),
                :production_centre => Centre.find_by_name!('ICS'),
                :gene => @cbx1

        es_cell = Factory.create(:es_cell,
          :name => 'EPD0027_2_A01',
          :gene => @cbx1,
          :mutation_subtype => 'conditional_ready',
          :ikmc_project_id => 35505,
          :allele_symbol_superscript => 'tm1a(EUCOMM)Wtsi'
        )

        bash_wtsi_attempt = Factory.create :mi_attempt,
                :es_cell => es_cell,
                :consortium_name => 'BaSH',
                :production_centre_name => 'WTSI',
                :mouse_allele_type => 'c',
                :colony_background_strain => Strain::ColonyBackgroundStrain.find_by_name!('C57BL/6N')
        bash_wtsi_plan = bash_wtsi_attempt.mi_plan

        bash_wtsi_plan.status_stamps.destroy_all
        bash_wtsi_plan.status_stamps.create!(:status => MiPlan::Status['Assigned'],
          :created_at => '2011-11-01 23:59:59.999 UTC')
        bash_wtsi_plan.status_stamps.create!(:status => MiPlan::Status['Interest'],
          :created_at => '2011-10-25 00:00:00 UTC')
        bash_wtsi_plan.status_stamps.create!(:status => MiPlan::Status['Assigned'],
          :created_at => '2011-11-02 00:00:00 UTC')

        bash_wtsi_plan.sub_project = MiPlan::SubProject.find_by_name!('Legacy EUCOMM')
        bash_wtsi_plan.priority = MiPlan::Priority.find_by_name!('Medium')
        bash_wtsi_plan.number_of_es_cells_starting_qc = 4
        bash_wtsi_plan.save!
        bash_wtsi_plan.status_stamps.last.update_attributes!(
          :created_at => '2011-11-03 23:59:59.999 UTC')

        bash_wtsi_plan.number_of_es_cells_passing_qc = 3
        bash_wtsi_plan.save!
        bash_wtsi_plan.status_stamps.last.update_attributes!(
          :created_at => '2011-11-04 23:59:59.999 UTC')

        bash_wtsi_attempt.status_stamps.first.update_attributes!(
          :created_at => '2011-11-22 00:00:00 UTC')
        bash_wtsi_attempt.status_stamps.create!(:mi_attempt_status => MiAttemptStatus.micro_injection_in_progress,
          :created_at => '2011-11-21 00:00:00 UTC')
        set_mi_attempt_genotype_confirmed(bash_wtsi_attempt)
        bash_wtsi_attempt.status_stamps.last.update_attributes!(
          :created_at => '2011-11-23 00:00:00 UTC')

        bash_wtsi_attempt.phenotype_attempts.create!
        pt = bash_wtsi_attempt.phenotype_attempts.last

        pt.status_stamps.first.update_attributes!(
          :created_at => '2011-12-01 23:59:59 UTC')
        pt.status_stamps.create!(:status => PhenotypeAttempt::Status['Rederivation Started'],
          :created_at => '2011-12-02 00:00:00 UTC')
        pt.status_stamps.create!(:status => PhenotypeAttempt::Status['Rederivation Complete'],
          :created_at => '2011-12-03 00:00:00 UTC')
        pt.status_stamps.create!(:status => PhenotypeAttempt::Status['Cre Excision Started'],
          :created_at => '2011-12-04 00:00:00 UTC')
        pt.status_stamps.create!(:status => PhenotypeAttempt::Status['Cre Excision Complete'],
          :created_at => '2011-12-05 00:00:00 UTC')
        pt.status_stamps.create!(:status => PhenotypeAttempt::Status['Phenotyping Started'],
          :created_at => '2011-12-06 00:00:00 UTC')
        pt.status_stamps.create!(:status => PhenotypeAttempt::Status['Phenotyping Complete'],
          :created_at => '2011-12-07 00:00:00 UTC')
        pt.is_active = false; pt.save!
        pt.status_stamps.last.update_attributes!(
          :created_at => '2011-12-08 23:59:59 UTC')

        mgp_wtsi_attempt = Factory.create :mi_attempt,
                :es_cell => es_cell,
                :consortium_name => 'MGP',
                :production_centre_name => 'WTSI'
        mgp_wtsi_plan = mgp_wtsi_attempt.mi_plan

        mgp_wtsi_plan.status_stamps.first.update_attributes!(
          :created_at => '2011-12-11 23:59:59.999 UTC')

        mgp_wtsi_attempt.status_stamps.first.update_attributes!(
          :created_at => '2011-12-12 00:00:00 UTC')
        mgp_wtsi_attempt.is_active = false; mgp_wtsi_attempt.save!
        mgp_wtsi_attempt.status_stamps.last.update_attributes!(
          :created_at => '2011-12-13 00:00:00 UTC')


        ee_wtsi_plan = Factory.create :mi_plan,
                :consortium => Consortium.find_by_name!('EUCOMM-EUMODIC'),
                :production_centre => Centre.find_by_name!('WTSI')

        pt = ee_wtsi_plan.phenotype_attempts.create!(:mi_attempt => bash_wtsi_attempt,
          :created_at => '2012-01-01 23:59:59 UTC')
        pt.status_stamps.destroy_all
        pt.status_stamps.create!(:created_at => '2012-01-01 23:59:59 UTC',
          :status => PhenotypeAttempt::Status['Phenotype Attempt Registered'])

        pt = ee_wtsi_plan.phenotype_attempts.create!(:mi_attempt => bash_wtsi_attempt,
          :created_at => '2012-01-01 23:59:59 UTC')
        pt.status_stamps.destroy_all
        pt.status_stamps.create!(:created_at => '2011-12-30 23:59:59 UTC',
          :status => PhenotypeAttempt::Status['Phenotype Attempt Registered'])

        @report = Reports::MiProduction::Intermediate.generate
      end

      should 'have columns in correct order' do
        expected = [
          'Consortium',
          'Sub-Project',
          'Priority',
          'Production Centre',
          'Gene',
          'MGI Accession ID',
          'Overall Status',
          'MiPlan Status',
          'MiAttempt Status',
          'PhenotypeAttempt Status',
          'IKMC Project ID',
          'Mutation Sub-Type',
          'Allele Symbol',
          'Genetic Background',
          'Assigned Date',
          'Assigned - ES Cell QC In Progress Date',
          'Assigned - ES Cell QC Complete Date',
          'Micro-injection in progress Date',
          'Genotype confirmed Date',
          'Micro-injection aborted Date',
          'Phenotype Attempt Registered Date',
          'Rederivation Started Date',
          'Rederivation Complete Date',
          'Cre Excision Started Date',
          'Cre Excision Complete Date',
          'Phenotyping Started Date',
          'Phenotyping Complete Date',
          'Phenotype Attempt Aborted Date',
          'Distinct Genotype Confirmed ES Cells',
          'Distinct Old Non Genotype Confirmed ES Cells'
        ]

        assert_equal expected, @report.column_names
      end

      should 'have correct values for each row when phenotype attempt is present and all optional MiAttempt values are present' do
        bash_wtsi_row = @report.find {|r| r.data['Consortium'] == 'BaSH' && r.data['Production Centre'] == 'WTSI'}
        expected = {
          'Consortium' => 'BaSH',
          'Sub-Project' => 'Legacy EUCOMM',
          'Priority' => 'Medium',
          'Production Centre' => 'WTSI',
          'Gene' => 'Cbx1',
          'MGI Accession ID' => 'MGI:105369',
          'Overall Status' => 'Phenotype Attempt Aborted',
          'MiPlan Status' => 'Assigned - ES Cell QC Complete',
          'MiAttempt Status' => 'Genotype confirmed',
          'PhenotypeAttempt Status' => 'Phenotype Attempt Aborted',
          'IKMC Project ID' => '35505',
          'Mutation Sub-Type' => 'conditional_ready',
          'Allele Symbol' => 'Cbx1<sup>tm1c(EUCOMM)Wtsi</sup>',
          'Genetic Background' => 'C57BL/6N',
          'Assigned Date' => '2011-11-02',
          'Assigned - ES Cell QC In Progress Date' => '2011-11-03',
          'Assigned - ES Cell QC Complete Date' => '2011-11-04',
          'Micro-injection in progress Date' => '2011-11-22',
          'Genotype confirmed Date' => '2011-11-23',
          'Micro-injection aborted Date' => '',
          'Phenotype Attempt Registered Date' => '2011-12-01',
          'Rederivation Started Date' => '2011-12-02',
          'Rederivation Complete Date' => '2011-12-03',
          'Cre Excision Started Date' => '2011-12-04',
          'Cre Excision Complete Date' => '2011-12-05',
          'Phenotyping Started Date' => '2011-12-06',
          'Phenotyping Complete Date' => '2011-12-07',
          'Phenotype Attempt Aborted Date' => '2011-12-08',
          'Distinct Genotype Confirmed ES Cells'=>1,
          'Distinct Old Non Genotype Confirmed ES Cells'=>0,
        }
        assert_equal expected, bash_wtsi_row.data
      end

      should 'have correct values for each row when only aborted MiAttempt is present and no PhenotypeAttempt' do
        mgp_wtsi_row = @report.find {|r| r.data['Consortium'] == 'MGP' && r.data['Production Centre'] == 'WTSI'}
        expected = {
          'Consortium' => 'MGP',
          'Sub-Project' => '',
          'Priority' => 'High',
          'Production Centre' => 'WTSI',
          'Gene' => 'Cbx1',
          'MGI Accession ID' => 'MGI:105369',
          'Overall Status' => 'Micro-injection aborted',
          'MiPlan Status' => 'Assigned',
          'MiAttempt Status' => 'Micro-injection aborted',
          'PhenotypeAttempt Status' => '',
          'IKMC Project ID' => '35505',
          'Mutation Sub-Type' => 'conditional_ready',
          'Allele Symbol' => 'Cbx1<sup>tm1a(EUCOMM)Wtsi</sup>',
          'Genetic Background' => '',
          'Assigned Date' => '2011-12-11',
          'Assigned - ES Cell QC In Progress Date' => '',
          'Assigned - ES Cell QC Complete Date' => '',
          'Micro-injection in progress Date' => '2011-12-12',
          'Genotype confirmed Date' => '',
          'Micro-injection aborted Date' => '2011-12-13',
          'Phenotype Attempt Registered Date' => '',
          'Rederivation Started Date' => '',
          'Rederivation Complete Date' => '',
          'Cre Excision Started Date' => '',
          'Cre Excision Complete Date' => '',
          'Phenotyping Started Date' => '',
          'Phenotyping Complete Date' => '',
          'Phenotype Attempt Aborted Date' => '',
          'Distinct Genotype Confirmed ES Cells'=>0,
          'Distinct Old Non Genotype Confirmed ES Cells'=>0,
        }
        assert_equal expected, mgp_wtsi_row.data
      end

      should 'show MiPlan status when there is no MI attempt or PhenotypeAttempt' do
        bash_ics_row = @report.find {|r| r.data['Consortium'] == 'BaSH' && r.data['Production Centre'] == 'ICS'}
        assert_equal 'Interest', bash_ics_row.data['Overall Status']
        assert_equal 'Interest', bash_ics_row.data['MiPlan Status']
        assert_equal 'MGI:105369', bash_ics_row.data['MGI Accession ID']
        assert_equal '', bash_ics_row.data['MiAttempt Status']
        assert_equal '', bash_ics_row.data['PhenotypeAttempt Status']
        assert_equal '', bash_ics_row['IKMC Project ID']
        assert_equal '', bash_ics_row['Mutation Sub-Type']
        assert_equal '', bash_ics_row['Allele Symbol']
        assert_equal '', bash_ics_row['Genetic Background']
      end

      should 'have correct values when there is a PhenotypeAttempt but no MI attempt' do
        ee_wtsi_row = @report.find {|r| r.data['Consortium'] == 'EUCOMM-EUMODIC' && r.data['Production Centre'] == 'WTSI'}
        assert_equal 'Phenotype Attempt Registered', ee_wtsi_row['Overall Status']
        assert_equal '', ee_wtsi_row['MiAttempt Status']
        assert_equal 'Phenotype Attempt Registered', ee_wtsi_row['PhenotypeAttempt Status']
        assert_equal '', ee_wtsi_row['Micro-injection in progress Date']
        assert_equal '2012-01-01', ee_wtsi_row['Phenotype Attempt Registered Date']
      end

      should 'not have values for empty columns' do
        bash_ics_row = @report.find {|r| r.data['Consortium'] == 'BaSH' && r.data['Production Centre'] == 'ICS'}
        [
          'Assigned Date',
          'Assigned - ES Cell QC Complete Date',
          'Micro-injection in progress Date',
          'Genotype confirmed Date',
          'Micro-injection aborted Date'
        ].each do |column_name|
          assert_equal '', bash_ics_row.data.fetch(column_name), "#{column_name} should be blank"
        end
      end

      should 'not have columns for statuses that are not wanted in the report' do
        bash_ics_row = @report.find {|r| r.data['Consortium'] == 'BaSH' && r.data['Production Centre'] == 'ICS'}
        assert_equal false, bash_ics_row.data.include?('Interest Date')
      end

    end # general tests

    should 'sort by all the fields in order' do
      cbx2 = Factory.create :gene, :marker_symbol => 'Cbx2'
      Factory.create :mi_plan,
              :consortium => Consortium.find_by_name!('MGP'),
              :production_centre => Centre.find_by_name!('WTSI'),
              :gene => @cbx1
      Factory.create :mi_plan,
              :consortium => Consortium.find_by_name!('JAX'),
              :production_centre => Centre.find_by_name!('WTSI'),
              :gene => @cbx1
      Factory.create :mi_plan,
              :consortium => Consortium.find_by_name!('JAX'),
              :production_centre => Centre.find_by_name!('JAX'),
              :gene => cbx2
      Factory.create :mi_plan,
              :consortium => Consortium.find_by_name!('JAX'),
              :production_centre => Centre.find_by_name!('JAX'),
              :gene => @cbx1
      expected = [
        ['JAX', '', 'High', 'JAX', 'Cbx1'],
        ['JAX', '', 'High', 'JAX', 'Cbx2'],
        ['JAX', '', 'High', 'WTSI', 'Cbx1'],
        ['MGP', '', 'High', 'WTSI', 'Cbx1']
      ]

      report = Reports::MiProduction::Intermediate.generate
      got = report.map {|r| r.data.values[0..4]}

      assert_equal expected, got
    end

    should 'has ::report_name of mi_production_intermediate' do
      assert_equal 'mi_production_intermediate', Reports::MiProduction::Intermediate.report_name
    end

    should 'have ::generate_and_cache' do
      Factory.create :mi_plan
      Reports::MiProduction::Intermediate.generate_and_cache
      assert ReportCache.find_by_name 'mi_production_intermediate'
    end

  end
end
