require 'test_helper'
require 'pp'

class IntermediateReportTest < ActiveSupport::TestCase
  context 'IntermediateReport' do

    setup do
      @cbx1 = Factory.create :gene_cbx1

      Factory.create :mi_plan,
      :consortium => Consortium.find_by_name!('BaSH'),
      :production_centre => Centre.find_by_name!('ICS'),
      :gene => @cbx1,
      :is_bespoke_allele => true

      allele = Factory.create(:allele, :gene => @cbx1)

      es_cell = Factory.create(:es_cell,
      :name => 'EPD0027_2_A01',
      :allele => allele,
      :mutation_subtype => 'conditional_ready',
      :ikmc_project_id => 35505,
      :allele_symbol_superscript => 'tm1a(EUCOMM)Wtsi'
      )

      bash_wtsi_attempt = Factory.create :wtsi_mi_attempt_genotype_confirmed,
      :es_cell => es_cell,
      :consortium_name => 'BaSH',
      :production_centre_name => 'WTSI',
      :mouse_allele_type => 'c',
      :colony_background_strain => Strain.find_by_name!('C57BL/6N')
      replace_status_stamps(bash_wtsi_attempt,
      'Micro-injection in progress' => '2011-11-22 00:00:00 UTC',
      'Chimeras obtained' => '2011-11-22 23:59:59 UTC',
      'Genotype confirmed' => '2011-11-23 00:00:00 UTC'
      )

      bash_wtsi_plan = bash_wtsi_attempt.mi_plan
      replace_status_stamps(bash_wtsi_plan, :asg => '2011-11-02')

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
      :gene => @cbx1,
      :consortium => Consortium.find_by_name!('EUCOMM-EUMODIC'),
      :production_centre => Centre.find_by_name!('WTSI'),
      :is_bespoke_allele => false

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

      report = Reports::MiProduction::Intermediate.new
      report.cache
    end

    should 'have correct attributes' do
      attributes = [
        :consortium,
        :sub_project,
        :priority,
        :production_centre,
        :gene,
        :mgi_accession_id,
        :overall_status,
        :mi_plan_status,
        :mi_attempt_status,
        :phenotype_attempt_status,
        :ikmc_project_id,
        :mutation_sub_type,
        :allele_symbol,
        :genetic_background,
        :assigned_date,
        :assigned_es_cell_qc_in_progress_date,
        :assigned_es_cell_qc_complete_date,
        :micro_injection_in_progress_date,
        :chimeras_obtained_date,
        :genotype_confirmed_date,
        :micro_injection_aborted_date,
        :phenotype_attempt_registered_date,
        :rederivation_started_date,
        :rederivation_complete_date,
        :cre_excision_started_date,
        :cre_excision_complete_date,
        :phenotyping_started_date,
        :phenotyping_complete_date,
        :phenotype_attempt_aborted_date,
        :distinct_genotype_confirmed_es_cells,
        :distinct_old_non_genotype_confirmed_es_cells,
        :mi_plan_id
      ]

      attributes.each do |attribute|
        assert_should have_db_column(attribute)
      end
    end

    should '#generate' do
      IntermediateReport.generate(Reports::MiProduction::Intermediate.new.report)
      assert_equal 4, IntermediateReport.count
    end

    should 'handle is_bespoke_allele correctly' do
      IntermediateReport.generate(Reports::MiProduction::Intermediate.new.report)
      assert_equal 4, IntermediateReport.count
      assert_equal true, IntermediateReport.all[0].attributes["is_bespoke_allele"]
      assert_equal false, IntermediateReport.all[3].attributes["is_bespoke_allele"]
    end
  end
end
