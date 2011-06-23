require 'test_helper'

class ReportsControllerTest < ActionController::TestCase
  context 'The reports controller' do
    should 'require authentication' do
      get :index
      assert_false response.success?
      assert_redirected_to new_user_session_path
    end
    
    context 'when authorised' do
      setup do
        create_common_test_objects
        sign_in default_user
      end
      
      context 'on the /microinjection_list report' do
        should 'be blank without parameters' do
          get :microinjection_list
          assert response.success?
          assert_nil assigns(:report)
        end
        
        should 'generate a full report with parameters' do
          get :microinjection_list, 'commit' => 'Go'
          assert response.success?
          assert assigns(:report)
          assert assigns(:report).is_a? Ruport::Data::Table
        end
      end
    end
  end
end
