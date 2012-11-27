require 'test_helper'

class TargRep::PipelinesControllerTest < ActionController::TestCase
  context "TargRep::PipelinesController" do
    setup do
      sign_in Factory.create(:admin_user)
    end

    should "get index" do
      # html
      get :index, :format => "html"
      assert_response :success, "should get index as html"
      assert_not_nil assigns(:pipelines)
      
      # json
      get :index, :format => "json"
      assert_response :success, "should get index as json"
      
      # xml
      get :index, :format => "xml"
      assert_response :success, "should get index as xml"
    end
    
    should "get new" do
      get :new
      assert_response :success
    end

    should "create pipeline" do
      assert_difference('TargRep::Pipeline.count') do
        post :create, :targ_rep_pipeline => Factory.attributes_for(:pipeline)
      end

      assert_redirected_to assigns(:pipeline)
    end
    
    should "not create pipeline" do
      assert_no_difference('TargRep::Pipeline.count') do
        post :create, :targ_rep_pipeline => Factory.attributes_for(:invalid_pipeline)
      end
    end

    should "show pipeline" do
      # html
      get :show, :id => TargRep::Pipeline.first.id
      assert_response :success, "should show pipeline as html"
      
      # json
      get :show, :id => TargRep::Pipeline.first.id, :format => "json"
      assert_response :success, "should show pipeline as json"
      
      # xml
      get :show, :id => TargRep::Pipeline.first.id, :format => "xml"
      assert_response :success, "should show pipeline as xml"
    end

    should "get edit" do
      get :edit, :id => TargRep::Pipeline.first.to_param
      assert_response :success
    end

    should "update pipeline" do
      put :update, :id => TargRep::Pipeline.first.id, :targ_rep_pipeline => Factory.attributes_for(:pipeline)
      assert_redirected_to assigns(:pipeline)
    end
    
    should "not update pipeline" do
      put :update, :id => TargRep::Pipeline.first.id, :targ_rep_pipeline => { :name => nil }
    end

    should "destroy pipeline" do
      assert_difference('TargRep::Pipeline.count', -1) do
        delete :destroy, :id => TargRep::Pipeline.first.to_param
      end

      assert_redirected_to [:targ_rep, :pipelines]
    end
  end
end
