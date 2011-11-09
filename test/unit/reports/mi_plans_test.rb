# encoding: utf-8

require 'test_helper'

class Reports::MiPlansTest < ActiveSupport::TestCase
  
  context 'Reports::MiPlans' do

    #should 'check gene list creation' do
    #
    #  Factory.create :gene
    #  Factory.create :mi_plan
    #
    #  assert Gene.all.size > 0, "Could not get Gene list"
    #  assert MiPlan.all.size > 0, "Could not get MiPlan list"
    #
    #  plans = Reports::MiPlans.new
    #
    #  assert plans, "Could not create plans"
    #
    #  genes = plans.get_genes
    #
    #  assert genes, "Could not get genes"
    #  assert genes.keys.count > 0, "Could not find genes (found: #{genes.keys.count})"
    #  
    #end

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
          
    #    puts MiPlan.all.map { |i| i.to_json }
          
#sql = 'select gene_id
#      from mi_plans
#      where mi_plan_status_id = 1
#      group by gene_id
#      having count(*) > 1'
#
#sql = 'select gene_id, mi_plan_status_id from mi_plans'
#
#sql = 'select * from mi_plans'
#
#    result = ActiveRecord::Base.connection.select_all( sql )
#
#        assert result && result.size > 0, "Invalid result set"
#        
#        result.each do |row|
#          puts row.inspect
#        end
        


        report = Reports::MiPlans::DoubleAssignment.get_double_assigned_1
        assert report, "Could not get report"
        columns = Reports::MiPlans::DoubleAssignment.get_double_assigned_1_columns
        assert columns && columns.size > 0, "Could not get columns"
        
        puts report.to_s
        
        columns.each do |column|
          values = report.column(column)
          counter = 0
          values.each do |value|
#            assert value == '' || value == 0, "Expected value to be empty (Column: #{column} / Row: #{counter}) Value: #{value} - #{columns[counter]}"
            assert value == '' || value == 0,
              "Expected value to be empty (Column: #{column} / Row: #{counter}) Value: #{value} - #{columns[counter]}" if column != 'KOMP2/JAX' && columns[counter] != 'KOMP2/BaSH'
            counter += 1
          end
          
        end
      
    end

    should 'display double-assignments between two consortia without production centres'
    
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
    
        report = Reports::MiPlans::DoubleAssignment.get_double_assigned_1
        assert report, "Could not get report"
        columns = Reports::MiPlans::DoubleAssignment.get_double_assigned_1_columns
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
