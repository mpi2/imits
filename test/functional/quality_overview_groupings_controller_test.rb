require 'test_helper'

class QualityOverviewGroupingsControllerTest < ActionController::TestCase

  context 'QualityOverviewGroupingsController' do

    should 'require authentication' do
      get :summary
      assert_false response.success?
      assert_redirected_to new_user_session_path
    end

    context 'GET summary' do
      setup do
        sign_in default_user
      end

      should 'work in XML format' do
        get :summary, :format => :xml
      end
    end

  end

end
