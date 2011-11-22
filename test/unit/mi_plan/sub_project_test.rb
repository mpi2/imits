require 'test_helper'

class MiPlan::SubProjectTest < ActiveSupport::TestCase
  
  VERBOSE = true
  
  context 'MiPlan::SubProject' do

    should have_db_column(:name).with_options(:null => false)
  
  #  should have_many :mi_plans, :foreign_key => :mi_plan_sub_project_id
  
#    should 'check sub-project assignment' do
#
##        gene_trafd1 = Factory.create :gene_trafd1
##
##        plan = Factory.create :mi_plan, :gene => gene_trafd1
##        
##        sub_project = MiPlan::SubProject.all.first
##        
##        puts sub_project.inspect if VERBOSE
##        
##        plan.mi_plan_sub_project_id = sub_project.id
##
##        puts plan.inspect if VERBOSE
##        
###        assert_equals sub_project.id, plan.mi_plan_sub_project_id
#
#
#
#        #mi_plan_status = MiPlanStatus.first
#        #assert_equal mi_plan_status.name, MiPlan::StatusStamp.new(:mi_plan_status_id => mi_plan_status.id).name
#
#
#       # sub_project = MiPlan::SubProject.first
#       # puts sub_project.inspect if VERBOSE
#       ##assert_equal sub_project.name, MiPlan::SubProject.new(:mi_plan_sub_project_id => sub_project.id).name
#
#  #describe MiPlan do
#  #  it { should have_many(:mi_plan_sub_projects)}
#  #end
#
# #   g = MiPlan.reflect_on_association(:mi_plan_sub_projects)
#  #  g.macro.should == :has_many
#
#
#
#        sub_project = MiPlan::SubProject.first
#        puts sub_project.inspect if VERBOSE
#        #sub_project.mi_plans
#        #assert_equal sub_project.name, MiPlan::SubProject.new(:mi_plan_sub_project_id => sub_project.id).name
#        gene_trafd1 = Factory.create :gene_trafd1
#        plan = Factory.create :mi_plan, :gene => gene_trafd1,
#          :mi_plan_status => MiPlanStatus['Assigned'],
#          #:mi_plan_sub_project => 2 #MiPlan::SubProject['Viral']
#          :mi_plan_sub_project => sub_project #SubProject['Viral']
#        
#        
#        puts plan.inspect if VERBOSE
#        
#        #          :mi_plan_status => MiPlanStatus['Assigned']
#
#
#        
#      #  plan.mi_plan_sub_project = sub_project
#       # assert_equal sub_project, plan.mi_plan_sub_project        
#    end
#

#    should 'check sub-project assignment' do
#      sub_project = MiPlan::SubProject.first
#      puts sub_project.inspect if VERBOSE
#      #sub_project.mi_plans
#      #assert_equal sub_project.name, MiPlan::SubProject.new(:mi_plan_sub_project_id => sub_project.id).name
##      gene_trafd1 = Factory.create :gene_trafd1
##      plan = Factory.create :mi_plan, :gene => gene_trafd1
#      #:mi_plan_status => MiPlanStatus['Assigned']#,
#      #:mi_plan_sub_project => 2 #MiPlan::SubProject['Viral']
#     #:mi_plan_sub_project => sub_project #SubProject['Viral']     
# 
#        gene_cbx1 = Factory.create :gene_cbx1
#        plan = Factory.create :mi_plan, :gene => gene_cbx1,
#          :consortium => Consortium.find_by_name!('BaSH'),
#          :production_centre => Centre.find_by_name!('WTSI'),
#          :mi_plan_status => MiPlanStatus['Assigned'] #,
#          #:mi_plan_sub_project => MiPlan::SubProject['Viral']
#
#      puts plan.inspect if VERBOSE
#
#     # plan.mi_plan_sub_project = sub_project
#
#
#    end

    #should 'have indexing' do
    #  sub_project = MiPlan::SubProject['Viral']          
    #  assert_equal "Viral", sub_project.name
    #end

    should 'check has_many mi_plans' do

      sub_project = MiPlan::SubProject.first
      
      puts sub_project.inspect if VERBOSE
      
      plan = Factory.build :mi_plan
      
      puts plan.inspect if VERBOSE
      
      #plan.sub_project = sub_project
      
      plan.sub_project.id = sub_project.id

      assert_equal sub_project, plan.sub_project

      puts plan.inspect if VERBOSE

    end

  end
  
end
