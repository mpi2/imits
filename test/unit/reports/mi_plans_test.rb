# encoding: utf-8

require 'test_helper'

class Reports::MiPlansTest < ActiveSupport::TestCase

  def trafd1; @trafd1 ||= Factory.create :gene_trafd1; end
  context 'Reports::MiPlans::DoubleAssignment' do

    should 'return consortia names' do
      test_columns = ["BaSH", "DTCC", "JAX",
        "DTCC-Legacy",
        "Helmholtz GMC", "MARC", "MGP", "MGP-KOMP",
        "Monterotondo", "MRC", "NorCOMM2", "Phenomin", "RIKEN BRC", "EUCOMM-EUMODIC", "UCD-KOMP", "MGP Legacy"]

      Consortium.all.each { |i| test_columns.delete(i.funding) if ! test_columns.include?(i.name) }

      columns = Reports::MiPlans::DoubleAssignment.get_consortia
      assert_equal test_columns, columns
    end

    should 'ensure column order (matrix)' do
      assert cbx1
      es_cell_cbx1 = Factory.create :es_cell, :gene => cbx1

      plan = TestDummy.mi_plan('BaSH', 'WTSI', :gene => cbx1, :force_assignment => true)
      Factory.create :mi_attempt2, :es_cell => es_cell_cbx1,
              :mi_plan => plan

      Factory.create :mi_attempt2, :es_cell => es_cell_cbx1,
              :mi_plan => TestDummy.mi_plan('JAX', 'JAX', :gene => cbx1, :force_assignment => true)

      assert trafd1
      es_cell_trafd1 = Factory.create :es_cell, :gene => trafd1

      Factory.create :mi_attempt2, :es_cell => es_cell_trafd1,
              :mi_plan => TestDummy.mi_plan('BaSH', 'WTSI', :gene => trafd1, :force_assignment => true)

      Factory.create :mi_attempt2, :es_cell => es_cell_trafd1,
              :mi_plan => TestDummy.mi_plan('JAX', 'JAX', :gene => trafd1, :force_assignment => true)

      report = Reports::MiPlans::DoubleAssignment.get_matrix
      assert !report.blank?
      columns = Reports::MiPlans::DoubleAssignment.get_matrix_columns
      assert !columns.blank?

      expected_columns = ["BaSH", "DTCC", "JAX",
        "DTCC-Legacy",
        "Helmholtz GMC", "MARC", "MGP", "MGP-KOMP",
        "Monterotondo", "MRC", "NorCOMM2", "Phenomin", "RIKEN BRC",
        "EUCOMM-EUMODIC", "UCD-KOMP", "MGP Legacy"]

      assert_equal expected_columns, columns

    end

    should 'display double-assignments between two consortia and production centres (matrix)' do

      assert cbx1
      es_cell_cbx1 = Factory.create :es_cell, :gene => cbx1

      Factory.create :mi_attempt2, :es_cell => es_cell_cbx1,
              :mi_plan => TestDummy.mi_plan('BaSH', 'WTSI', :gene => cbx1, :force_assignment => true)

      Factory.create :mi_attempt2, :es_cell => es_cell_cbx1,
              :mi_plan => TestDummy.mi_plan('JAX', 'JAX', :gene => cbx1, :force_assignment => true)

      assert trafd1
      es_cell_trafd1 = Factory.create :es_cell, :gene => trafd1

      Factory.create :mi_attempt2, :es_cell => es_cell_trafd1,
              :mi_plan => TestDummy.mi_plan('BaSH', 'WTSI', :gene => trafd1, :force_assignment => true)

      Factory.create :mi_attempt2, :es_cell => es_cell_trafd1,
              :mi_plan => TestDummy.mi_plan('JAX', 'JAX', :gene => trafd1, :force_assignment => true)

      report = Reports::MiPlans::DoubleAssignment.get_matrix
      assert !report.blank?
      columns = Reports::MiPlans::DoubleAssignment.get_matrix_columns
      assert !columns.blank?
      assert_equal 2, report.column('JAX')[0]

      columns.each do |column|
        values = report.column(column)
        counter = 0
        values.each do |value|
          assert value == '' || value == 0,
                  "Expected value to be empty (Column: #{column} / Row: #{counter}) Value: #{value} - #{columns[counter]}" if column != 'JAX' && columns[counter] != 'BaSH'
          counter += 1
        end

      end

    end


    should 'not display a value when no double-assignment (matrix)' do

      assert cbx1
      es_cell_cbx1 = Factory.create :es_cell, :gene => cbx1

      Factory.create :mi_attempt2, :es_cell => es_cell_cbx1,
              :mi_plan => TestDummy.mi_plan('BaSH', 'WTSI', :gene => cbx1, :force_assignment => true)

      Factory.create :mi_attempt2, :es_cell => es_cell_cbx1,
              :mi_plan => TestDummy.mi_plan('JAX', 'JAX', :gene => cbx1, :force_assignment => true),
              :is_active => false

      assert trafd1
      es_cell_trafd1 = Factory.create :es_cell, :gene => trafd1

      Factory.create :mi_attempt2, :es_cell => es_cell_trafd1,
              :mi_plan => TestDummy.mi_plan('BaSH', 'WTSI', :gene => trafd1, :force_assignment => true)

      Factory.create :mi_attempt2, :es_cell => es_cell_trafd1,
              :mi_plan => TestDummy.mi_plan('JAX', 'JAX', :gene => trafd1, :force_assignment => true),
              :is_active => false


      report = Reports::MiPlans::DoubleAssignment.get_matrix
      assert !report.blank?
      columns = Reports::MiPlans::DoubleAssignment.get_matrix_columns
      assert !columns.blank?

      columns.each do |column|
        values = report.column(column)
        values.each do |value|
          assert value == '' || value == 0, "Expected value to be empty"
        end

      end

    end

    should 'not display double-assignment if no active mi_attempts have been assigned to mi_plans (matrix)' do
      assert cbx1
      Factory.create :mi_plan, :gene => cbx1,
              :consortium => Consortium.find_by_name!('BaSH'),
              :production_centre => Centre.find_by_name!('WTSI'),
              :force_assignment => true

      Factory.create :mi_plan, :gene => cbx1,
              :consortium => Consortium.find_by_name!('JAX'),
              :production_centre => Centre.find_by_name!('JAX'),
              :force_assignment => true

      assert trafd1
      Factory.create :mi_plan, :gene => trafd1,
              :consortium => Consortium.find_by_name!('BaSH'),
              :production_centre => Centre.find_by_name!('WTSI'),
              :force_assignment => true

      Factory.create :mi_plan, :gene => trafd1,
              :consortium => Consortium.find_by_name!('BaSH'),
              :production_centre => Centre.find_by_name!('ICS'),
              :force_assignment => true

      report = Reports::MiPlans::DoubleAssignment.get_matrix
      assert !report.blank?
      columns = Reports::MiPlans::DoubleAssignment.get_matrix_columns
      assert !columns.blank?

      columns.each do |column|
        values = report.column(column)
        values.each do |value|
          assert value == '' || value == 0, "Expected value to be empty"
        end

      end
    end

    should 'not display a value when no double-assignment (list)' do

      assert cbx1
      Factory.create :mi_plan, :gene => cbx1,
              :consortium => Consortium.find_by_name!('BaSH'),
              :production_centre => Centre.find_by_name!('WTSI'),
              :force_assignment => true

      assert trafd1
      Factory.create :mi_plan, :gene => trafd1,
              :consortium => Consortium.find_by_name!('BaSH'),
              :production_centre => Centre.find_by_name!('WTSI'),
              :force_assignment => true

      report = Reports::MiPlans::DoubleAssignment.get_list
      assert !report.blank?
      columns = Reports::MiPlans::DoubleAssignment::LIST_COLUMNS
      assert !columns.blank?

      assert_equal "", report.to_s

    end

    should 'have consortia on page (list)' do

      assert cbx1
      es_cell_cbx1 = Factory.create :es_cell, :gene => cbx1

      Factory.create :mi_attempt2, :es_cell => es_cell_cbx1,
              :mi_plan => TestDummy.mi_plan('BaSH', 'WTSI', :gene => cbx1, :force_assignment => true)

      Factory.create :mi_attempt2, :es_cell => es_cell_cbx1,
              :mi_plan => TestDummy.mi_plan('JAX', 'JAX', :gene => cbx1, :force_assignment => true)

      report = Reports::MiPlans::DoubleAssignment.get_list
      assert !report.blank?
      columns = Reports::MiPlans::DoubleAssignment::LIST_COLUMNS
      assert !columns.blank?

      assert report.to_s =~ /Double - Production for Consortium: BaSH:/, "Cannot find BaSH"
      assert report.to_s =~ /Double - Production for Consortium: JAX:/, "Cannot find JAX"

    end

    should 'display double-assignments between two consortia with production centres (list)' do

      assert cbx1
      es_cell_cbx1 = Factory.create :es_cell, :gene => cbx1

      Factory.create :mi_attempt2, :es_cell => es_cell_cbx1,
              :mi_plan => TestDummy.mi_plan('BaSH', 'WTSI', :gene => cbx1, :force_assignment => true)

      Factory.create :mi_attempt2, :es_cell => es_cell_cbx1,
              :mi_plan => TestDummy.mi_plan('JAX', 'JAX', :gene => cbx1, :force_assignment => true)

      report = Reports::MiPlans::DoubleAssignment.get_list_without_grouping
      assert !report.blank?
      columns = Reports::MiPlans::DoubleAssignment::LIST_COLUMNS
      assert !columns.blank?

      (0..3).each do |i|
        assert_equal 'Cbx1', report.column('Marker Symbol')[i]
        assert_equal 'Micro-injection in progress', report.column('MI Status')[i]
      end

      assert_equal ["BaSH", "JAX", "BaSH", "JAX"].sort, report.column('Consortium').sort
      assert_equal ["WTSI", "JAX", "WTSI", "JAX"].sort, report.column('Centre').sort

    end

  end

end
