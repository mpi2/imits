require 'test_helper'

class TargRep::JavascriptsControllerTest < ActionController::TestCase
  
  context "TargRep::Javascripts" do
    
    setup do
      sign_in default_user
    end

    should "allow us to GET /dynamic_esc_qc_conflict_selects" do
      get :dynamic_esc_qc_conflict_selects, :format => :js
      assert_response :success
    end

  end

end
