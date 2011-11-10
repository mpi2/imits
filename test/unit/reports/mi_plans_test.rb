# encoding: utf-8

require 'test_helper'

class Reports::MiPlansTest < ActiveSupport::TestCase
  
  context 'Reports::MiPlans' do

    should 'display double-assignments between two consortia and production centres' do

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
        
        assert report.column('KOMP2/JAX')[0] == 2, "Expected to find value 2"
          
        puts report.to_s
        
        columns.each do |column|
          values = report.column(column)
          counter = 0
          values.each do |value|
            assert value == '' || value == 0,
              "Expected value to be empty (Column: #{column} / Row: #{counter}) Value: #{value} - #{columns[counter]}" if column != 'KOMP2/JAX' && columns[counter] != 'KOMP2/BaSH'
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
        
#        puts MiPlan.all.map {|i| i.to_json }

        assert report.column('KOMP2/JAX')[0] == 1, "Expected to find value 1"
          
        puts report.to_s
        
        columns.each do |column|
          values = report.column(column)
          counter = 0
          values.each do |value|
            assert value == '' || value == 0,
              "Expected value to be empty (Column: #{column} / Row: #{counter}) Value: #{value} - #{columns[counter]}" if column != 'KOMP2/JAX' && columns[counter] != 'KOMP2/BaSH'
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
#        report = Reports::MiPlans::DoubleAssignment.get_list
        assert report, "Could not get report"
        columns = Reports::MiPlans::DoubleAssignment.get_list_columns
        assert columns && columns.size > 0, "Could not get columns"

        puts report.to_s
        
        #puts 'Marker Symbol: 0 - ' + report.column('Marker Symbol')[0].to_s
        #puts 'Marker Symbol: 1 - ' + report.column('Marker Symbol')[1].to_s
        #puts 'Marker Symbol: 2 - ' + report.column('Marker Symbol')[2].to_s
        #puts 'Marker Symbol: 3 - ' + report.column('Marker Symbol')[3].to_s
        #
        #puts 'Consortium: 0 - ' + report.column('Consortium')[0].to_s
        #puts 'Consortium: 1 - ' + report.column('Consortium')[1].to_s
        #puts 'Consortium: 2 - ' + report.column('Consortium')[2].to_s
        #puts 'Consortium: 3 - ' + report.column('Consortium')[3].to_s
        #
        #puts 'Plan Status: 0 - ' + report.column('Plan Status')[0].to_s
        #puts 'Plan Status: 1 - ' + report.column('Plan Status')[1].to_s
        #puts 'Plan Status: 2 - ' + report.column('Plan Status')[2].to_s
        #puts 'Plan Status: 3 - ' + report.column('Plan Status')[3].to_s
        #
        #puts 'Centre: 0 - ' + report.column('Centre')[0].to_s
        #puts 'Centre: 1 - ' + report.column('Centre')[1].to_s
        #puts 'Centre: 2 - ' + report.column('Centre')[2].to_s
        #puts 'Centre: 3 - ' + report.column('Centre')[3].to_s


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

        #columns.each do |column|
        #  values = report.column(column)
        #  values.each do |value|
        #    puts values.to_s
        #  end
        #  
        #end
        
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
        
#        report = Reports::MiPlans::DoubleAssignment.get_list_raw
        report = Reports::MiPlans::DoubleAssignment.get_list
        assert report, "Could not get report"
        columns = Reports::MiPlans::DoubleAssignment.get_list_columns
        assert columns && columns.size > 0, "Could not get columns"

        puts report.to_s
        #puts "LENGTH: " + report.to_s.length.to_s
        
        assert report.to_s.length == 0, "Expected report to be empty!"
        
    end    

    should 'have consortia on page (list)' do
      
        #gene_cbx1 = Factory.create :gene_cbx1
        #Factory.create :mi_plan, :gene => gene_cbx1,
        #  :consortium => Consortium.find_by_name('BaSH'),
        #  :production_centre => Centre.find_by_name('WTSI'),
        #  :mi_plan_status => MiPlanStatus['Assigned']
   
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

        puts report.to_s

        assert report.to_s =~ /DOUBLE-ASSIGNMENTS FOR consortium: BaSH:/, "Cannot find BaSH"
        assert report.to_s =~ /DOUBLE-ASSIGNMENTS FOR consortium: JAX:/, "Cannot find JAX"
#        assert report.to_s =~ /DOUBLE-ASSIGNMENTS FOR consortium: sid:/, "Cannot find sid"
      
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

        puts report.to_s

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
    
  end
  
end
