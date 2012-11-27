require 'test_helper'

class TargRep::ReportsControllerTest < ActionController::TestCase
  context "TargRep::ReportsController" do
    setup do
      sign_in default_user

      Factory.create :es_cell
      Factory.create :es_cell
      Factory.create :es_cell
    end
    
    should "get index" do
      get :index
      assert_response :success
    end
  end
end
