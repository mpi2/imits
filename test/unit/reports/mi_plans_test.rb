# encoding: utf-8

require 'test_helper'

class Reports::MiPlansTest < ActiveSupport::TestCase
  
  VERBOSE = false
  
  context 'Reports::MiPlans' do

    should 'ensure column order (matrix)' do

        gene_cbx1 = Factory.create :gene_cbx1
        Factory.create :mi_plan, :gene => gene_cbx1,
          :consortium => Consortium.find_by_name('BaSH'),
          :production_centre => Centre.find_by_name('WTSI'),
          :mi_plan_status => MiPlanStatus['Assigned']
        
        Factory.create :mi_plan, :gene => gene_cbx1,
          :consortium => Consortium.find_by_name('JAX'),
          :production_centre => Centre.find_by_name('JAX'),
          :number_of_es_cells_starting_qc => 5
        
        gene_trafd1 = Factory.create :gene_trafd1
        Factory.create :mi_plan, :gene => gene_trafd1,
          :consortium => Consortium.find_by_name('BaSH'),
          :production_centre => Centre.find_by_name('WTSI'),
          :mi_plan_status => MiPlanStatus['Assigned']
        
        Factory.create :mi_plan, :gene => gene_trafd1,
          :consortium => Consortium.find_by_name('JAX'),
          :production_centre => Centre.find_by_name('JAX'),
          :number_of_es_cells_starting_qc => 5
          
        report = Reports::MiPlans::DoubleAssignment.get_matrix
        assert report, "Could not get report"
        columns = Reports::MiPlans::DoubleAssignment.get_matrix_columns
        assert columns && columns.size > 0, "Could not get columns"
 
        puts columns.inspect if VERBOSE
        
        # any new consortia entries will be tagged to end & not explicitly tested

        test_columns = ["KOMP2 - BaSH", "KOMP2 - DTCC", "KOMP - JAX", "EUCOMM / EUMODIC - Helmholtz GMC", "Infrafrontier/BMBF - MARC",
                      "KOMP2 - MGP", "China - Monterotondo", "Wellcome Trust - MRC", "KOMP / Wellcome Trust - NorCOMM2",
                      "European Union - Phenomin", "MRC - RIKEN BRC", "Genome Canada - DTCC-KOMP",
                      "Phenomin - EUCOMM-EUMODIC", "Japanese government - MGP-KOMP"]

        counter = 0
        test_columns.each do |i|
          assert i == columns[counter]
          puts columns[counter] if VERBOSE
          counter += 1
        end
        
    end
    
    should 'display double-assignments between two consortia and production centres (matrix)' do

        gene_cbx1 = Factory.create :gene_cbx1
        Factory.create :mi_plan, :gene => gene_cbx1,
          :consortium => Consortium.find_by_name('BaSH'),
          :production_centre => Centre.find_by_name('WTSI'),
          :mi_plan_status => MiPlanStatus['Assigned']

        Factory.create :mi_plan, :gene => gene_cbx1,
          :consortium => Consortium.find_by_name('JAX'),
          :production_centre => Centre.find_by_name('JAX'),
          :number_of_es_cells_starting_qc => 5

        gene_trafd1 = Factory.create :gene_trafd1
        Factory.create :mi_plan, :gene => gene_trafd1,
          :consortium => Consortium.find_by_name('BaSH'),
          :production_centre => Centre.find_by_name('WTSI'),
          :mi_plan_status => MiPlanStatus['Assigned']

        Factory.create :mi_plan, :gene => gene_trafd1,
          :consortium => Consortium.find_by_name('JAX'),
          :production_centre => Centre.find_by_name('JAX'),
          :number_of_es_cells_starting_qc => 5
          
        report = Reports::MiPlans::DoubleAssignment.get_matrix
        assert report, "Could not get report"
        columns = Reports::MiPlans::DoubleAssignment.get_matrix_columns
        assert columns && columns.size > 0, "Could not get columns"
                 
        puts report.to_s if VERBOSE

        assert report.column('KOMP - JAX')[0] == 2, "Expected to find value 2"
        
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
          :consortium => Consortium.find_by_name('BaSH'),
          :mi_plan_status => MiPlanStatus['Assigned']

        Factory.create :mi_plan, :gene => gene_cbx1,
          :consortium => Consortium.find_by_name('JAX'),
          :mi_plan_status => MiPlanStatus['Assigned']
      
        report = Reports::MiPlans::DoubleAssignment.get_matrix
        assert report, "Could not get report"
        columns = Reports::MiPlans::DoubleAssignment.get_matrix_columns
        assert columns && columns.size > 0, "Could not get columns"
        
        assert report.column('KOMP - JAX')[0] == 1, "Expected to find value 1"
          
        puts report.to_s if VERBOSE
        
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
          :consortium => Consortium.find_by_name('BaSH'),
          :production_centre => Centre.find_by_name('WTSI'),
          :mi_plan_status => MiPlanStatus['Assigned']

        Factory.create :mi_plan, :gene => gene_cbx1,
          :consortium => Consortium.find_by_name('JAX'),
          :production_centre => Centre.find_by_name('JAX'),
          :mi_plan_status => MiPlanStatus['Interest']
    
        gene_trafd1 = Factory.create :gene_trafd1
        Factory.create :mi_plan, :gene => gene_trafd1,
          :consortium => Consortium.find_by_name('BaSH'),
          :production_centre => Centre.find_by_name('WTSI'),
          :mi_plan_status => MiPlanStatus['Assigned']
    
        Factory.create :mi_plan, :gene => gene_trafd1,
          :consortium => Consortium.find_by_name('BaSH'),
          :production_centre => Centre.find_by_name('ICS'),
          :mi_plan_status => MiPlanStatus['Interest']
    
        report = Reports::MiPlans::DoubleAssignment.get_matrix
        assert report, "Could not get report"
        columns = Reports::MiPlans::DoubleAssignment.get_matrix_columns
        assert columns && columns.size > 0, "Could not get columns"
        
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
          :consortium => Consortium.find_by_name('BaSH'),
          :mi_plan_status => MiPlanStatus['Assigned']

        Factory.create :mi_plan, :gene => gene_cbx1,
          :consortium => Consortium.find_by_name('JAX'),
          :mi_plan_status => MiPlanStatus['Assigned']
      
        report = Reports::MiPlans::DoubleAssignment.get_list_raw
        assert report, "Could not get report"
        columns = Reports::MiPlans::DoubleAssignment.get_list_columns
        assert columns && columns.size > 0, "Could not get columns"

        puts report.to_s if VERBOSE
        
        assert report.column('Marker Symbol')[0] == 'Cbx1'
        assert report.column('Marker Symbol')[1] == 'Cbx1'
        assert report.column('Marker Symbol')[2] == 'Cbx1'
        assert report.column('Marker Symbol')[3] == 'Cbx1'

        assert report.column('Consortium')[0] == 'JAX'
        assert report.column('Consortium')[1] == 'BaSH'
        assert report.column('Consortium')[2] == 'JAX'
        assert report.column('Consortium')[3] == 'BaSH'

        assert report.column('Plan Status')[0] == 'Assigned'
        assert report.column('Plan Status')[1] == 'Assigned'
        assert report.column('Plan Status')[2] == 'Assigned'
        assert report.column('Plan Status')[3] == 'Assigned'

        assert report.column('Centre')[0] == 'NONE'
        assert report.column('Centre')[1] == 'NONE'
        assert report.column('Centre')[2] == 'NONE'
        assert report.column('Centre')[3] == 'NONE'
        
    end

    should 'not display a value when no double-assignment (list)' do
      
        gene_cbx1 = Factory.create :gene_cbx1
        Factory.create :mi_plan, :gene => gene_cbx1,
          :consortium => Consortium.find_by_name('BaSH'),
          :production_centre => Centre.find_by_name('WTSI'),
          :mi_plan_status => MiPlanStatus['Assigned']
   
        gene_trafd1 = Factory.create :gene_trafd1
        Factory.create :mi_plan, :gene => gene_trafd1,
          :consortium => Consortium.find_by_name('BaSH'),
          :production_centre => Centre.find_by_name('WTSI'),
          :mi_plan_status => MiPlanStatus['Assigned']
        
        report = Reports::MiPlans::DoubleAssignment.get_list
        assert report, "Could not get report"
        columns = Reports::MiPlans::DoubleAssignment.get_list_columns
        assert columns && columns.size > 0, "Could not get columns"

        puts report.to_s if VERBOSE
        
        assert report.to_s.length == 0, "Expected report to be empty!"
        
    end    

    should 'have consortia on page (list)' do
      
        gene_trafd1 = Factory.create :gene_trafd1
        Factory.create :mi_plan, :gene => gene_trafd1,
          :consortium => Consortium.find_by_name('BaSH'),
          :production_centre => Centre.find_by_name('WTSI'),
          :mi_plan_status => MiPlanStatus['Assigned']
        
        Factory.create :mi_plan, :gene => gene_trafd1,
          :consortium => Consortium.find_by_name('JAX'),
          :production_centre => Centre.find_by_name('JAX'),
          :mi_plan_status => MiPlanStatus['Assigned']
        
        report = Reports::MiPlans::DoubleAssignment.get_list
        assert report, "Could not get report"
        columns = Reports::MiPlans::DoubleAssignment.get_list_columns
        assert columns && columns.size > 0, "Could not get columns"

        puts report.to_s if VERBOSE

        assert report.to_s =~ /DOUBLE-ASSIGNMENTS FOR consortium: BaSH:/, "Cannot find BaSH"
        assert report.to_s =~ /DOUBLE-ASSIGNMENTS FOR consortium: JAX:/, "Cannot find JAX"
      
    end

    should 'display double-assignments between two consortia with production centres (list)' do

        gene_trafd1 = Factory.create :gene_trafd1
        
        Factory.create :mi_plan, :gene => gene_trafd1,
          :consortium => Consortium.find_by_name('BaSH'),
          :production_centre => Centre.find_by_name('WTSI'),
          :mi_plan_status => MiPlanStatus['Assigned']
        
        Factory.create :mi_plan, :gene => gene_trafd1,
          :consortium => Consortium.find_by_name('JAX'),
          :production_centre => Centre.find_by_name('JAX'),
          :mi_plan_status => MiPlanStatus['Assigned']
        
        report = Reports::MiPlans::DoubleAssignment.get_list_raw
        assert report, "Could not get report"
        columns = Reports::MiPlans::DoubleAssignment.get_list_columns
        assert columns && columns.size > 0, "Could not get columns"

        puts report.to_s if VERBOSE

        assert report.column('Marker Symbol')[0] == 'Trafd1'
        assert report.column('Marker Symbol')[1] == 'Trafd1'
        assert report.column('Marker Symbol')[2] == 'Trafd1'
        assert report.column('Marker Symbol')[3] == 'Trafd1'
        
        assert report.column('Consortium')[0] == 'JAX'
        assert report.column('Consortium')[1] == 'BaSH'
        assert report.column('Consortium')[2] == 'JAX'
        assert report.column('Consortium')[3] == 'BaSH'
        
        assert report.column('Plan Status')[0] == 'Assigned'
        assert report.column('Plan Status')[1] == 'Assigned'
        assert report.column('Plan Status')[2] == 'Assigned'
        assert report.column('Plan Status')[3] == 'Assigned'
        
        assert report.column('Centre')[0] == 'JAX'
        assert report.column('Centre')[1] == 'WTSI'
        assert report.column('Centre')[2] == 'JAX'
        assert report.column('Centre')[3] == 'WTSI'

    end

    should 'display double-assignments between two consortia with production centres and mi_attempts (list)' do
                 
        gene_trafd1 = Factory.create :gene_trafd1
        
        Factory.create :mi_attempt,
          :es_cell => Factory.create(:es_cell, :gene => gene_trafd1),
          'mi_date' => '2011-11-05',
          :mi_attempt_status => MiAttemptStatus.micro_injection_in_progress,
          :production_centre_name => 'WTSI',
          :consortium_name => 'BaSH'

        Factory.create :mi_attempt,
          :es_cell => Factory.create(:es_cell, :gene => gene_trafd1),
          'mi_date' => '2011-10-05',
          :mi_attempt_status => MiAttemptStatus.micro_injection_in_progress,
          :production_centre_name => 'WTSI',
          :consortium_name => 'DTCC'
                                    
        report = Reports::MiPlans::DoubleAssignment.get_list_raw
        assert report, "Could not get report"
        columns = Reports::MiPlans::DoubleAssignment.get_list_columns
        assert columns && columns.size > 0, "Could not get columns"

        puts report.to_s if VERBOSE
        
        assert report.column('Marker Symbol')[0] == 'Trafd1'
        assert report.column('Marker Symbol')[1] == 'Trafd1'
        assert report.column('Marker Symbol')[2] == 'Trafd1'
        assert report.column('Marker Symbol')[3] == 'Trafd1'
        
        assert report.column('Consortium')[0] == 'BaSH'
        assert report.column('Consortium')[1] == 'DTCC'
        assert report.column('Consortium')[2] == 'BaSH'
        assert report.column('Consortium')[3] == 'DTCC'
        
        assert report.column('Plan Status')[0] == 'Assigned'
        assert report.column('Plan Status')[1] == 'Assigned'
        assert report.column('Plan Status')[2] == 'Assigned'
        assert report.column('Plan Status')[3] == 'Assigned'

        assert report.column('MI Status')[0] == 'Micro-injection in progress'
        assert report.column('MI Status')[1] == 'Micro-injection in progress'
        assert report.column('MI Status')[2] == 'Micro-injection in progress'
        assert report.column('MI Status')[3] == 'Micro-injection in progress'
        
        assert report.column('Centre')[0] == 'WTSI'
        assert report.column('Centre')[1] == 'WTSI'
        assert report.column('Centre')[2] == 'WTSI'
        assert report.column('Centre')[3] == 'WTSI'

        assert report.column('MI Date')[0] == '2011-11-05'
        assert report.column('MI Date')[1] == '2011-10-05'
        assert report.column('MI Date')[2] == '2011-11-05'
        assert report.column('MI Date')[3] == '2011-10-05'

    end
    
  end
  
end
