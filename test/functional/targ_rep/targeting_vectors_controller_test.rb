require 'test_helper'

class TargRep::TargetingVectorsControllerTest < ActionController::TestCase

  context "TargRep::TargetingVectorsController" do

    setup do
      sign_in default_user

      Factory.create :targeting_vector
    end
      
    should "not allow us to GET /edit" do
      assert_raise(AbstractController::ActionNotFound) { get :edit }
    end
    
    should "not allow us to GET /new" do
      assert_raise(AbstractController::ActionNotFound) { get :new }
    end
    
    should "allow us to GET /index" do
      get :index, :format => :js
      assert_response :success
      assert_not_nil assigns(:targeting_vectors)
    end
    
    should "allow us to create and update a targeting vector we made" do
      pipeline       = TargRep::Pipeline.first
      targ_vec_attrs = Factory.attributes_for :targeting_vector

      assert_difference('TargRep::TargetingVector.count') do
        post :create, :format => :json, :targ_rep_targeting_vector => {
          :name        => targ_vec_attrs[:name],
          :allele_id   => TargRep::TargetingVector.first.allele_id,
          :pipeline_id => pipeline.id
        }
      end

      assert_response :success
      
      created_targ_vec = TargRep::TargetingVector.find_by_name(targ_vec_attrs[:name])
      created_targ_vec.save
      
      # UPDATE
      attrs = Factory.attributes_for :targeting_vector
      put :update, :format => :json, :id => created_targ_vec.id, :targ_rep_targeting_vector => { :name => 'new name' }
      assert_response :success
    end

    should_eventually "allow us to create, update and delete a targeting vector we made" do
      pipeline       = TargRep::Pipeline.first
      targ_vec_attrs = Factory.attributes_for :targeting_vector

      assert_difference('TargRep::TargetingVector.count') do
        post :create, :targ_rep_targeting_vector => {
          :name        => targ_vec_attrs[:name],
          :allele_id   => TargRep::TargetingVector.first.allele_id,
          :pipeline_id => pipeline.id
        }
      end

      assert_response :success
      
      created_targ_vec = TargRep::TargetingVector.find_by_name(targ_vec_attrs[:name])
      created_targ_vec.save
      
      # UPDATE
      attrs = Factory.attributes_for :targ_rep_targeting_vector
      put :update, :id => created_targ_vec.id, :targeting_vector => { :name => 'new name' }
      assert_response :success
      
      # DELETE
      assert_difference('TargRep::TargetingVector.count', -1) do
        delete :destroy, :id => created_targ_vec.id
      end
      assert_response :success
    end
    
    should "show targeting vector" do
      targ_vec_id = TargRep::TargetingVector.first.to_param
      
      get :show, :format => "html", :id => targ_vec_id
      assert_response 406, "Controller should_eventually not allow HTML display"
      
      get :show, :format => "json", :id => targ_vec_id
      assert_response :success, "Controller does not allow JSON display"
      
      get :show, :format => "xml", :id => targ_vec_id
      assert_response :success, "Controller does not allow XML display"
    end
    
    should "not allow us to update a targeting_vector with invalid parameters" do
      pipeline         = TargRep::Pipeline.first
      targ_vec_attrs   = Factory.attributes_for :targeting_vector
      another_targ_vec = Factory.create :targeting_vector
      
      # CREATE a valid Targeting Vector
      targ_vec_attrs = Factory.attributes_for :targeting_vector
      assert_difference('TargRep::TargetingVector.count') do
        post :create, :format => :json, :targ_rep_targeting_vector => {
          :name        => targ_vec_attrs[:name],
          :allele_id   => TargRep::TargetingVector.first.allele_id,
          :pipeline_id => pipeline.id
        }
      end
      assert_response :success
      
      created_targ_vec = TargRep::TargetingVector.find_by_name(targ_vec_attrs[:name])
      
      # UPDATE - should_eventually fail as the name is already taken
      put :update, :format => :json, :id => created_targ_vec.id, :targ_rep_targeting_vector => { :name => another_targ_vec.name }
      assert_response :unprocessable_entity
      
      # UPDATE - should_eventually fail as we're not allowed a nil allele_id
      put :update, :format => :json, :id => created_targ_vec.id, :targ_rep_targeting_vector => { :allele_id => nil }
      assert_response :unprocessable_entity
    end
    
    should "not allow us to delete a targeting_vector when we are not an admin" do
      assert_no_difference('TargRep::TargetingVector.count') do
        delete :destroy, :format => :json, :id => TargRep::TargetingVector.first.id
      end
      assert_response 302
    end

  end

end
