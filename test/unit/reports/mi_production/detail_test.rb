# encoding: utf-8

require 'test_helper'

class Reports::MiProduction::DetailTest < ActiveSupport::TestCase
  context 'Reports::MiProduction::Detail' do

    should 'have correct columns including sub_project' do
      expected = [
        'Consortium',
        'Sub-Project',
        'Is Bespoke Allele',
        'Priority',
        'Production Centre',
        'Gene',
        'Status',
        'Assigned Date',
        'Assigned - ES Cell QC In Progress Date',
        'Assigned - ES Cell QC Complete Date',
        'Micro-injection in progress Date',
        'Chimeras obtained Date',
        'Genotype confirmed Date',
        'Micro-injection aborted Date',
        'Phenotype Attempt Registered Date',
        'Cre Excision Started Date',
        'Cre Excision Complete Date',
        "Phenotyping Started Date",
        'Phenotyping Complete Date',
        'Phenotype Attempt Aborted Date'
      ]

      Factory.create :mi_plan
      user = Factory.build(:user)
      Reports::MiProduction::Intermediate.new.cache
      report = Reports::MiProduction::Detail.generate
      assert_equal expected, report.column_names
    end


    should 'be generated off the intermediate production report minus some columns' do
      assert cbx1
      allele = Factory.create(:allele, :gene => cbx1)
      mi = Factory.create :mi_attempt2,
              :mi_plan => bash_wtsi_cbx1_plan,
              :es_cell => Factory.create(:es_cell, :allele => allele)

      plan = mi.mi_plan
      plan.number_of_es_cells_passing_qc = 5; plan.save!

      user = Factory.build(:user)
      Factory.create :mi_plan
      Reports::MiProduction::Intermediate.new.cache
      report = Reports::MiProduction::Detail.generate
      row = report.find {|r| r['Gene'] == 'Cbx1'}
      assert_equal 'BaSH', row['Consortium']
      assert_equal 'WTSI', row['Production Centre']
      assert_equal 'Cbx1', row['Gene']
      assert ! row['Assigned - ES Cell QC Complete Date'].blank?
      assert ! row['Micro-injection in progress Date'].blank?
      assert row['Genotype confirmed Date'].blank?
      assert ! row.data.has_key?('MiPlan Status')
      assert_equal 'Micro-injection in progress', row['Status']
    end

  end
end
