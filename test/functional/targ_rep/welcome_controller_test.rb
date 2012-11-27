require 'test_helper'

class TargRep::WelcomeControllerTest < ActionController::TestCase
  
  context "TargRep::WelcomeController" do
    setup do
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