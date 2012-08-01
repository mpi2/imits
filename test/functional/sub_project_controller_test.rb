require 'test_helper'

class SubProjectsControllerTest < ActionController::TestCase
  context 'SubProjectsController' do

    setup do
      sign_in default_user
    end

    context 'POST create' do
      should 'add a sub project' do
        post :create, :mi_plan_sub_project=>{:name => 'FUNCTIONALTEST'}
        assert_equal "Sub-project 'FUNCTIONALTEST' created", flash[:notice]
        end

      should 'fail; sub projects must be unique' do

        sub_project = MiPlan::SubProject.new(:name => 'FUNCTIONALTEST')
        sub_project.save!
        post :create, :mi_plan_sub_project=>{:name => 'FUNCTIONALTEST'}
        assert_equal "has already been taken", flash[:alert]
      end
    end

    context 'GET index' do

      should 'show all sub projects' do
        sp = MiPlan::SubProject.find(:all, :order=>"name")
        get :index, :format => :json
        assert_equal sp.to_json, response.body
      end
    end

    context 'POST delete' do
      should 'delete sub project' do
        sub_project = MiPlan::SubProject.new(:name => 'FUNCTIONALTEST')
        sub_project.save!
        post :destroy, :id => sub_project.id
        assert_equal "Successfully deleted sub-project 'FUNCTIONALTEST'", flash[:notice]
      end

      should 'not delete sub project' do
        sub_project = MiPlan::SubProject.new(:name => 'FUNCTIONALTEST')
        sub_project.save!
        plan = Factory.build :mi_plan
        plan.sub_project_id = sub_project.id
        plan.save!
        post :destroy, :id => sub_project.id
        assert_equal "Sub-project 'FUNCTIONALTEST' Could not be deleted", flash[:alert]
      end
    end
  end
end
