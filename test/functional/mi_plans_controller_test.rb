require 'test_helper'

class MiPlansControllerTest < ActionController::TestCase
  context 'The reports controller' do
    should 'require authentication' do
      get :gene_selection
      assert_false response.success?
      assert_redirected_to new_user_session_path
    end

    context 'when authorised' do
      setup do
        create_common_test_objects
        sign_in default_user
      end
    end
  end
end
