require 'test_helper'

class QualityOverviewGroupingsControllerTest < ActionController::TestCase

  context 'QualityOverviewGroupingsController' do

    should 'require authentication' do
      get :index
      assert_false response.success?
      assert_redirected_to new_user_session_path
    end

  end

end
