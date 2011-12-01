# encoding: utf-8

require 'test_helper'

class Reports::MiProduction::DetailTest < ActiveSupport::TestCase
  context 'Reports::MiProduction::Detail' do

    setup do
      @cbx1 = Factory.create :gene_cbx1
    end

    context 'general tests' do
      setup do
        Factory.create :mi_plan,
                :consortium => Consortium.find_by_name!('BaSH'),
                :production_centre => Centre.find_by_name!('ICS'),
                :gene => @cbx1
        Factory.create :mi_plan,
                :consortium => Consortium.find_by_name!('EUCOMM-EUMODIC'),
                :production_centre => Centre.find_by_name!('WTSI')

        bash_wtsi_attempt = Factory.create :mi_attempt,
                :es_cell => Factory.create(:es_cell, :gene => @cbx1),
                :consortium_name => 'BaSH',
                :production_centre_name => 'WTSI'
        bash_wtsi_plan = bash_wtsi_attempt.mi_plan

        bash_wtsi_plan.status_stamps.first.update_attributes!(
          :created_at => '2011-11-01 23:59:59.999 UTC')
        bash_wtsi_plan.status_stamps.create!(:mi_plan_status => MiPlanStatus['Interest'],
          :created_at => '2011-10-25 00:00:00 UTC')
        bash_wtsi_plan.status_stamps.create!(:mi_plan_status => MiPlanStatus['Assigned'],
          :created_at => '2011-11-02 00:00:00 UTC')

        bash_wtsi_plan.sub_project = MiPlan::SubProject.find_by_name!('Legacy EUCOMM')
        bash_wtsi_plan.priority = 'Medium'
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
        bash_wtsi_attempt.status_stamps.create!(:mi_attempt_status => MiAttemptStatus.genotype_confirmed,
          :created_at => '2011-11-23 00:00:00 UTC')
        bash_wtsi_attempt.is_active = false; bash_wtsi_attempt.save!
        bash_wtsi_attempt.status_stamps.last.update_attributes!(
          :created_at => '2011-11-25 23:59:59.999 UTC')

        @report = Reports::MiProduction::Detail.generate
      end

      should 'have columns in correct order' do
        expected = [
          'Consortium',
          'Sub-Project',
          'Priority',
          'Production Centre',
          'Gene',
          'Assigned Date',
          'Assigned - ES Cell QC In Progress Date',
          'Assigned - ES Cell QC Complete Date',
          'Micro-injection in progress Date',
          'Genotype confirmed Date',
          'Micro-injection aborted Date'
        ]

        assert_equal expected, @report.column_names
      end

      should 'have correct values for fully-populated rows' do
        bash_wtsi_row = @report.find {|r| r.data['Consortium'] == 'BaSH' && r.data['Production Centre'] == 'WTSI'}
        expected = {
          'Consortium' => 'BaSH',
          'Sub-Project' => 'Legacy EUCOMM',
          'Priority' => 'Medium',
          'Production Centre' => 'WTSI',
          'Gene' => 'Cbx1',
          'Assigned Date' => '2011-11-02',
          'Assigned - ES Cell QC In Progress Date' => '2011-11-03',
          'Assigned - ES Cell QC Complete Date' => '2011-11-04',
          'Micro-injection in progress Date' => '2011-11-22',
          'Genotype confirmed Date' => '2011-11-23',
          'Micro-injection aborted Date' => '2011-11-25'
        }
        assert_equal expected, bash_wtsi_row.data
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
          assert_nil bash_ics_row.data.fetch(column_name), "#{column_name} should be blank"
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
              :consortium => Consortium.find_by_name!('JAX'),
              :production_centre => Centre.find_by_name!('JAX'),
              :gene => @cbx1
      Factory.create :mi_plan,
              :consortium => Consortium.find_by_name!('JAX'),
              :production_centre => Centre.find_by_name!('WTSI'),
              :gene => @cbx1
      Factory.create :mi_plan,
              :consortium => Consortium.find_by_name!('MGP'),
              :production_centre => Centre.find_by_name!('WTSI'),
              :gene => @cbx1
      Factory.create :mi_plan,
              :consortium => Consortium.find_by_name!('JAX'),
              :production_centre => Centre.find_by_name!('JAX'),
              :gene => cbx2
      expected = [
        ['JAX', '', 'High', 'JAX', 'Cbx1'],
        ['JAX', '', 'High', 'JAX', 'Cbx2'],
        ['JAX', '', 'High', 'WTSI', 'Cbx1'],
        ['MGP', '', 'High', 'WTSI', 'Cbx1']
      ]

      report = Reports::MiProduction::Detail.generate
      got = report.map {|r| r.data.values[0..4]}

      assert_equal expected, got
    end
  end

end
