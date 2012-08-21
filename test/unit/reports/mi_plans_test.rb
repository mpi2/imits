# encoding: utf-8

require 'test_helper'

class Reports::MiPlansTest < ActiveSupport::TestCase

  context 'Reports::MiPlans::DoubleAssignment' do

    should 'return funding names' do
      test_columns = [ "KOMP2", "KOMP2", "KOMP2",
        "KOMP312/KOMP",
        "Infrafrontier/BMBF", "China",
        "Wellcome Trust", "Wellcome Trust", "European Union", "MRC", "Genome Canada", "Phenomin",
        "Japanese government", "EUCOMM / EUMODIC", "KOMP / Wellcome Trust", "KOMP" ]

      columns = Reports::MiPlans::DoubleAssignment.get_funding

      assert_equal test_columns, columns
    end

    should 'return consortia names' do
      test_columns = ["BaSH", "DTCC", "JAX",
        "DTCC-Legacy",
        "Helmholtz GMC", "MARC", "MGP", "MGP Legacy",
        "Monterotondo", "MRC", "NorCOMM2", "Phenomin", "RIKEN BRC", "EUCOMM-EUMODIC", "MGP-KOMP", "UCD-KOMP"]

      Consortium.all.each { |i| test_columns.delete(i.funding) if ! test_columns.include?(i.name) }

      columns = Reports::MiPlans::DoubleAssignment.get_consortia

      assert_equal test_columns, columns
    end

    should 'ensure column order (matrix)' do

      gene_cbx1 = Factory.create :gene_cbx1
      Factory.create :mi_plan, :gene => gene_cbx1,
              :consortium => Consortium.find_by_name!('BaSH'),
              :production_centre => Centre.find_by_name!('WTSI'),
              :force_assignment => true

      Factory.create :mi_plan, :gene => gene_cbx1,
              :consortium => Consortium.find_by_name!('JAX'),
              :production_centre => Centre.find_by_name!('JAX'),
              :number_of_es_cells_starting_qc => 5

      gene_trafd1 = Factory.create :gene_trafd1
      Factory.create :mi_plan, :gene => gene_trafd1,
              :consortium => Consortium.find_by_name!('BaSH'),
              :production_centre => Centre.find_by_name!('WTSI'),
              :force_assignment => true

      Factory.create :mi_plan, :gene => gene_trafd1,
              :consortium => Consortium.find_by_name!('JAX'),
              :production_centre => Centre.find_by_name!('JAX'),
              :number_of_es_cells_starting_qc => 5

      report = Reports::MiPlans::DoubleAssignment.get_matrix
      assert !report.blank?
      columns = Reports::MiPlans::DoubleAssignment.get_matrix_columns
      assert !columns.blank?

      expected_columns = ["KOMP2 - BaSH", "KOMP2 - DTCC", "KOMP2 - JAX",
        "KOMP312/KOMP - DTCC-Legacy",
        "Infrafrontier/BMBF - Helmholtz GMC", "China - MARC", "Wellcome Trust - MGP", "Wellcome Trust - MGP Legacy",
        "European Union - Monterotondo", "MRC - MRC", "Genome Canada - NorCOMM2", "Phenomin - Phenomin", "Japanese government - RIKEN BRC",
        "EUCOMM / EUMODIC - EUCOMM-EUMODIC", "KOMP / Wellcome Trust - MGP-KOMP", "KOMP - UCD-KOMP"]

      assert_equal expected_columns, columns

    end

    should 'display double-assignments between two consortia and production centres (matrix)' do

      gene_cbx1 = Factory.create :gene_cbx1
      Factory.create :mi_plan, :gene => gene_cbx1,
              :consortium => Consortium.find_by_name!('BaSH'),
              :production_centre => Centre.find_by_name!('WTSI'),
              :force_assignment => true

      Factory.create :mi_plan, :gene => gene_cbx1,
              :consortium => Consortium.find_by_name!('JAX'),
              :production_centre => Centre.find_by_name!('JAX'),
              :number_of_es_cells_starting_qc => 5

      gene_trafd1 = Factory.create :gene_trafd1
      Factory.create :mi_plan, :gene => gene_trafd1,
              :consortium => Consortium.find_by_name!('BaSH'),
              :production_centre => Centre.find_by_name!('WTSI'),
              :force_assignment => true

      Factory.create :mi_plan, :gene => gene_trafd1,
              :consortium => Consortium.find_by_name!('JAX'),
              :production_centre => Centre.find_by_name!('JAX'),
              :number_of_es_cells_starting_qc => 5

      report = Reports::MiPlans::DoubleAssignment.get_matrix
      assert !report.blank?
      columns = Reports::MiPlans::DoubleAssignment.get_matrix_columns
      assert !columns.blank?

      assert_equal 2, report.column('KOMP2 - JAX')[0]

      columns.each do |column|
        values = report.column(column)
        counter = 0
        values.each do |value|
          assert value == '' || value == 0,
                  "Expected value to be empty (Column: #{column} / Row: #{counter}) Value: #{value} - #{columns[counter]}" if column != 'KOMP - JAX' && columns[counter] != 'KOMP2 - BaSH'
          counter += 1
        end

      end

    end

    should 'display double-assignments between two consortia without production centres (matrix)' do

      gene_cbx1 = Factory.create :gene_cbx1
      Factory.create :mi_plan, :gene => gene_cbx1,
              :consortium => Consortium.find_by_name!('BaSH'),
              :force_assignment => true

      Factory.create :mi_plan, :gene => gene_cbx1,
              :consortium => Consortium.find_by_name!('JAX'),
              :force_assignment => true

      report = Reports::MiPlans::DoubleAssignment.get_matrix
      assert !report.blank?
      columns = Reports::MiPlans::DoubleAssignment.get_matrix_columns
      assert !columns.blank?

      assert_equal 1, report.column('KOMP2 - JAX')[0]

      columns.each do |column|
        values = report.column(column)
        counter = 0
        values.each do |value|
          assert value == '' || value == 0,
                  "Expected value to be empty (Column: #{column} / Row: #{counter}) Value: #{value} - #{columns[counter]}" if column != 'KOMP2 - JAX' && columns[counter] != 'KOMP2 - BaSH'
          counter += 1
        end

      end

    end

    should 'not display a value when no double-assignment (matrix)' do

      gene_cbx1 = Factory.create :gene_cbx1
      Factory.create :mi_plan, :gene => gene_cbx1,
              :consortium => Consortium.find_by_name!('BaSH'),
              :production_centre => Centre.find_by_name!('WTSI'),
              :force_assignment => true

      Factory.create :mi_plan, :gene => gene_cbx1,
              :consortium => Consortium.find_by_name!('JAX'),
              :production_centre => Centre.find_by_name!('JAX'),
              :withdrawn => true

      gene_trafd1 = Factory.create :gene_trafd1
      Factory.create :mi_plan, :gene => gene_trafd1,
              :consortium => Consortium.find_by_name!('BaSH'),
              :production_centre => Centre.find_by_name!('WTSI'),
              :force_assignment => true

      Factory.create :mi_plan, :gene => gene_trafd1,
              :consortium => Consortium.find_by_name!('BaSH'),
              :production_centre => Centre.find_by_name!('ICS'),
              :withdrawn => true

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

    should 'display double-assignments between two consortia without production centres (list)' do

      gene_cbx1 = Factory.create :gene_cbx1

      Factory.create :mi_plan, :gene => gene_cbx1,
              :consortium => Consortium.find_by_name!('BaSH'),
              :force_assignment => true

      Factory.create :mi_plan, :gene => gene_cbx1,
              :consortium => Consortium.find_by_name!('JAX'),
              :force_assignment => true

      report = Reports::MiPlans::DoubleAssignment.get_list_without_grouping
      assert !report.blank?
      columns = Reports::MiPlans::DoubleAssignment::LIST_COLUMNS
      assert !columns.blank?

      assert_equal ["BaSH", "JAX", "BaSH", "JAX"].sort, report.column('Consortium').sort

      for i in (0..3)
        assert_equal 'Cbx1', report.column('Marker Symbol')[i]
        assert_equal 'Assigned', report.column('Plan Status')[i]
        assert_equal 'NONE', report.column('Centre')[i]
      end

    end

    should 'not display a value when no double-assignment (list)' do

      gene_cbx1 = Factory.create :gene_cbx1
      Factory.create :mi_plan, :gene => gene_cbx1,
              :consortium => Consortium.find_by_name!('BaSH'),
              :production_centre => Centre.find_by_name!('WTSI'),
              :force_assignment => true

      gene_trafd1 = Factory.create :gene_trafd1
      Factory.create :mi_plan, :gene => gene_trafd1,
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

      gene_trafd1 = Factory.create :gene_trafd1
      Factory.create :mi_plan, :gene => gene_trafd1,
              :consortium => Consortium.find_by_name!('BaSH'),
              :production_centre => Centre.find_by_name!('WTSI'),
              :force_assignment => true

      Factory.create :mi_plan, :gene => gene_trafd1,
              :consortium => Consortium.find_by_name!('JAX'),
              :production_centre => Centre.find_by_name!('JAX'),
              :force_assignment => true

      report = Reports::MiPlans::DoubleAssignment.get_list
      assert !report.blank?
      columns = Reports::MiPlans::DoubleAssignment::LIST_COLUMNS
      assert !columns.blank?

      assert report.to_s =~ /Double-Assignments for Consortium: BaSH:/, "Cannot find BaSH"
      assert report.to_s =~ /Double-Assignments for Consortium: JAX:/, "Cannot find JAX"

    end

    should 'display double-assignments between two consortia with production centres (list)' do

      gene_trafd1 = Factory.create :gene_trafd1

      Factory.create :mi_plan, :gene => gene_trafd1,
              :consortium => Consortium.find_by_name!('BaSH'),
              :production_centre => Centre.find_by_name!('WTSI'),
              :force_assignment => true

      Factory.create :mi_plan, :gene => gene_trafd1,
              :consortium => Consortium.find_by_name!('JAX'),
              :production_centre => Centre.find_by_name!('JAX'),
              :force_assignment => true

      report = Reports::MiPlans::DoubleAssignment.get_list_without_grouping
      assert !report.blank?
      columns = Reports::MiPlans::DoubleAssignment::LIST_COLUMNS
      assert !columns.blank?

      for i in (0..3)
        assert_equal 'Trafd1', report.column('Marker Symbol')[i]
        assert_equal 'Assigned', report.column('Plan Status')[i]
      end

      assert_equal ["BaSH", "JAX", "BaSH", "JAX"].sort, report.column('Consortium').sort
      assert_equal ["WTSI", "JAX", "WTSI", "JAX"].sort, report.column('Centre').sort

    end

    should 'display double-assignments between two consortia with production centres and mi_attempts (list)' do
      gene_trafd1 = Factory.create :gene_trafd1

      Factory.create :mi_attempt,
              :es_cell => Factory.create(:es_cell, :gene => gene_trafd1),
              'mi_date' => '2011-11-05',
              :status => MiAttempt::Status.micro_injection_in_progress,
              :production_centre_name => 'WTSI',
              :consortium_name => 'BaSH'

      Factory.create :mi_attempt,
              :es_cell => Factory.create(:es_cell, :gene => gene_trafd1),
              'mi_date' => '2011-10-05',
              :status => MiAttempt::Status.micro_injection_in_progress,
              :production_centre_name => 'WTSI',
              :consortium_name => 'DTCC'

      report = Reports::MiPlans::DoubleAssignment.get_list_without_grouping
      assert !report.blank?
      columns = Reports::MiPlans::DoubleAssignment::LIST_COLUMNS
      assert !columns.blank?

      assert_equal ['Trafd1','Trafd1','Trafd1','Trafd1'], report.column('Marker Symbol')
      assert_equal ['Assigned','Assigned','Assigned','Assigned'], report.column('Plan Status')
      assert_equal ['Micro-injection in progress','Micro-injection in progress','Micro-injection in progress','Micro-injection in progress'], report.column('MI Status')
      assert_equal ['WTSI','WTSI','WTSI','WTSI'], report.column('Centre')
      assert_equal ['DTCC','BaSH','DTCC','BaSH'].sort, report.column('Consortium').sort
      assert_equal ['2011-10-05','2011-11-05','2011-10-05','2011-11-05'].sort, report.column('MI Date').sort
    end

  end

end
