require 'test_helper'

class QualityOverviewsControllerTest < ActionController::TestCase

  context 'QualityOverviewsController' do

    should 'require authentication' do
      get :index
      assert_false response.success?
      assert_redirected_to new_user_session_path
    end

    context 'GET index' do
      setup do
        sign_in default_user
      end

      should 'work in XML format' do
        get :index, :format => :xml
      end
    end
  end

end
