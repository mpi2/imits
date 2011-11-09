# encoding: utf-8

require 'test_helper'

class Reports::MiPlansTest < ActiveSupport::TestCase
  
  context 'Reports::MiPlans' do

    should 'display double-assignments between two consortia and production centres' do

        gene_cbx1 = Factory.create :gene_cbx1
        Factory.create :mi_plan, :gene => gene_cbx1,
          :consortium => Consortium.find_by_name!('BaSH'),
          :production_centre => Centre.find_by_name!('WTSI'),
          :mi_plan_status => MiPlanStatus['Assigned']

        Factory.create :mi_plan, :gene => gene_cbx1,
          :consortium => Consortium.find_by_name!('JAX'),
          :production_centre => Centre.find_by_name!('JAX'),
          :number_of_es_cells_starting_qc => 5

        gene_trafd1 = Factory.create :gene_trafd1
        Factory.create :mi_plan, :gene => gene_trafd1,
          :consortium => Consortium.find_by_name!('BaSH'),
          :production_centre => Centre.find_by_name!('WTSI'),
          :mi_plan_status => MiPlanStatus['Assigned']

        Factory.create :mi_plan, :gene => gene_trafd1,
          :consortium => Consortium.find_by_name!('JAX'),
          :production_centre => Centre.find_by_name!('JAX'),
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
    
    #should 'get_rows' do
    #
    #array = MiPlanStatus.all_assigned
    #puts "ARRAY 1: " + array.inspect
    #newarray = []
    #array.map { |i| newarray.push(i.id) }
    #puts "ARRAY 2: " + newarray.inspect
    #
    #  #Recipe.find(:all, :conditions => "descr IN (select descr from Recipe group by descr having count(descr) > 1)")
    #  
    #  plans = MiPlan.all  #(:conditions => "mi_plan_status_id in (" + newarray.join(',').to_s + ") ")
    #  
    #  #assert plans.size > 0
    #                      
    #                      #,
    #    #  :group => "gene_id
    #     # having count(*) > 1")
    #
    #    puts plans.map {|i| i.to_json }
    #end

    should 'display double-assignments between two consortia without production centres' do  
    
        gene_cbx1 = Factory.create :gene_cbx1
        Factory.create :mi_plan, :gene => gene_cbx1,
          :consortium => Consortium.find_by_name!('BaSH'),
          :mi_plan_status => MiPlanStatus['Assigned']

        Factory.create :mi_plan, :gene => gene_cbx1,
          :consortium => Consortium.find_by_name!('JAX'),
          :mi_plan_status => MiPlanStatus['Assigned']
      
        report = Reports::MiPlans::DoubleAssignment.get_matrix
        assert report, "Could not get report"
        columns = Reports::MiPlans::DoubleAssignment.get_matrix_columns
        assert columns && columns.size > 0, "Could not get columns"
        
        puts MiPlan.all.map {|i| i.to_json }
        puts report.to_s
        
    end
    
    should 'not display a value when no double-assignment' do
      
        gene_cbx1 = Factory.create :gene_cbx1
        Factory.create :mi_plan, :gene => gene_cbx1,
          :consortium => Consortium.find_by_name!('BaSH'),
          :production_centre => Centre.find_by_name!('WTSI'),
          :mi_plan_status => MiPlanStatus['Assigned']

        Factory.create :mi_plan, :gene => gene_cbx1,
          :consortium => Consortium.find_by_name!('JAX'),
          :production_centre => Centre.find_by_name!('JAX'),
          :mi_plan_status => MiPlanStatus['Interest']
    
        gene_trafd1 = Factory.create :gene_trafd1
        Factory.create :mi_plan, :gene => gene_trafd1,
          :consortium => Consortium.find_by_name!('BaSH'),
          :production_centre => Centre.find_by_name!('WTSI'),
          :mi_plan_status => MiPlanStatus['Assigned']
    
        Factory.create :mi_plan, :gene => gene_trafd1,
          :consortium => Consortium.find_by_name!('BaSH'),
          :production_centre => Centre.find_by_name!('ICS'),
          :mi_plan_status => MiPlanStatus['Assigned']
    
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

  end
end
