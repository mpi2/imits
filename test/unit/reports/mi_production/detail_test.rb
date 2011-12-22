# encoding: utf-8

require 'test_helper'

class Reports::MiProduction::DetailTest < ActiveSupport::TestCase
  context 'Reports::MiProduction::Detail' do

    should 'have correct columns' do
      expected = [
        'Consortium',
        'Sub-Project',
        'Priority',
        'Production Centre',
        'Gene',
        'Status',
        'Assigned Date',
        'Assigned - ES Cell QC In Progress Date',
        'Assigned - ES Cell QC Complete Date',
        'Micro-injection in progress Date',
        'Genotype confirmed Date',
        'Micro-injection aborted Date',
        'Phenotype Attempt Registered Date',
        'Cre Excision Started Date',
        'Cre Excision Complete Date',
        'Phenotyping Complete Date',
        'Phenotype Attempt Aborted Date'
      ]

      Factory.create :mi_plan
      Reports::MiProduction::Intermediate.generate_and_cache
      report = Reports::MiProduction::Detail.generate
      assert_equal expected, report.column_names
    end

    should 'be generated off the intermediate production report minus some columns' do
      cbx1 = Factory.create(:gene_cbx1)

      mi = Factory.create :mi_attempt, :consortium_name => 'BaSH',
              :production_centre_name => 'WTSI',
              :es_cell => Factory.create(:es_cell, :gene => cbx1)
      plan = mi.mi_plan
      plan.number_of_es_cells_passing_qc = 5; plan.save!

      Factory.create :mi_plan
      Reports::MiProduction::Intermediate.generate_and_cache
      report = Reports::MiProduction::Detail.generate
      assert_equal 'BaSH', report.data[0]['Consortium']
      assert_equal 'WTSI', report.data[0]['Production Centre']
      assert_equal 'Cbx1', report.data[0]['Gene']
      assert ! report.data[0]['Assigned - ES Cell QC Complete Date'].blank?
      assert ! report.data[0]['Micro-injection in progress Date'].blank?
      assert report.data[0]['Genotype confirmed Date'].blank?
      assert ! report.data[0].data.has_key?('MiPlan Status')
      assert_equal 'Micro-injection in progress', report.data[0]['Status']
    end

  end
end
