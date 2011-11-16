# encoding: utf-8

require 'test_helper'

class Reports::MiPlansTest < ActiveSupport::TestCase
  
  VERBOSE = true
  
  context 'Reports::MiPlans' do

    should 'return consortia names' do
        test_columns = ["BaSH", "DTCC", "JAX", "Helmholtz GMC", "MARC", "MGP",
          "Monterotondo", "MRC", "NorCOMM2", "Phenomin", "RIKEN BRC", "EUCOMM-EUMODIC", "MGP-KOMP", "DTCC-KOMP"]        
        Consortium.all.each { |i| test_columns.delete(i.funding) if ! test_columns.include?(i.name) }        
        columns = Reports::MiPlans::DoubleAssignment.get_consortia
        
        assert_equal test_columns, columns      
    end

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

        test_columns = ["KOMP2 - BaSH", "KOMP2 - DTCC", "KOMP - JAX",
          "EUCOMM / EUMODIC - Helmholtz GMC", "Infrafrontier/BMBF - MARC",
          "KOMP2 - MGP", "China - Monterotondo", "Wellcome Trust - MRC", "KOMP / Wellcome Trust - NorCOMM2",
          "European Union - Phenomin", "MRC - RIKEN BRC", "Genome Canada - EUCOMM-EUMODIC",
          "Phenomin - MGP-KOMP", "Japanese government - DTCC-KOMP"]
        
        assert_equal test_columns, columns

        #counter = 0
        #test_columns.each do |i|
        #  assert_equal i, columns[counter]      
        #  puts columns[counter] if VERBOSE
        #  counter += 1
        #end
        
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

        assert_equal 2, report.column('KOMP - JAX')[0]
        
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
                  
        puts report.to_s if VERBOSE

        assert report.column('KOMP - JAX')[0] == 1, "Expected to find value 1"
        
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
      
        report = Reports::MiPlans::DoubleAssignment.get_list_without_grouping
        assert report, "Could not get report"
        columns = Reports::MiPlans::DoubleAssignment.get_list_columns
        assert columns && columns.size > 0, "Could not get columns"

        puts report.to_s if VERBOSE
        
        assert report.column('Marker Symbol')[0] == 'Cbx1'
        assert report.column('Marker Symbol')[1] == 'Cbx1'
        assert report.column('Marker Symbol')[2] == 'Cbx1'
        assert report.column('Marker Symbol')[3] == 'Cbx1'

        assert_equal "JAX", report.column('Consortium')[0]
        assert_equal "BaSH", report.column('Consortium')[1]
        assert_equal "JAX", report.column('Consortium')[2]
        assert_equal "BaSH", report.column('Consortium')[3]

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

        assert report.to_s =~ /Double-Assignments for Consortium: BaSH:/, "Cannot find BaSH"
        assert report.to_s =~ /Double-Assignments for Consortium: JAX:/, "Cannot find JAX"
      
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
        
        report = Reports::MiPlans::DoubleAssignment.get_list_without_grouping
        assert report, "Could not get report"
        columns = Reports::MiPlans::DoubleAssignment.get_list_columns
        assert columns && columns.size > 0, "Could not get columns"

        puts report.to_s if VERBOSE

        assert report.column('Marker Symbol')[0] == 'Trafd1'
        assert report.column('Marker Symbol')[1] == 'Trafd1'
        assert report.column('Marker Symbol')[2] == 'Trafd1'
        assert report.column('Marker Symbol')[3] == 'Trafd1'
        
        assert_equal "JAX", report.column('Consortium')[0]
        assert_equal "BaSH", report.column('Consortium')[1]
        assert_equal "JAX", report.column('Consortium')[2]
        assert_equal "BaSH", report.column('Consortium')[3]
        
        assert report.column('Plan Status')[0] == 'Assigned'
        assert report.column('Plan Status')[1] == 'Assigned'
        assert report.column('Plan Status')[2] == 'Assigned'
        assert report.column('Plan Status')[3] == 'Assigned'
        
        assert_equal "JAX", report.column('Centre')[0]
        assert_equal "WTSI", report.column('Centre')[1]
        assert_equal "JAX", report.column('Centre')[2]
        assert_equal "WTSI", report.column('Centre')[3]

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
                                    
        report = Reports::MiPlans::DoubleAssignment.get_list_without_grouping
        assert report, "Could not get report"
        columns = Reports::MiPlans::DoubleAssignment.get_list_columns
        assert columns && columns.size > 0, "Could not get columns"

        puts report.to_s if VERBOSE
        
        assert report.column('Marker Symbol')[0] == 'Trafd1'
        assert report.column('Marker Symbol')[1] == 'Trafd1'
        assert report.column('Marker Symbol')[2] == 'Trafd1'
        assert report.column('Marker Symbol')[3] == 'Trafd1'
                
        assert_equal "BaSH", report.column('Consortium')[0]
        assert_equal "DTCC", report.column('Consortium')[1]
        assert_equal "BaSH", report.column('Consortium')[2]
        assert_equal "DTCC", report.column('Consortium')[3]       
        
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

        assert_equal "2011-11-05", report.column('MI Date')[0]      
        assert_equal "2011-10-05", report.column('MI Date')[1]      
        assert_equal "2011-11-05", report.column('MI Date')[2]      
        assert_equal "2011-10-05", report.column('MI Date')[3]      

    end
    
  end
  
end
