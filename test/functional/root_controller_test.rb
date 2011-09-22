# encoding: utf-8

require 'test_helper'

class RootControllerTest < ActionController::TestCase
  context 'RootController' do

    should 'require authentication' do
      get :index
      assert_redirected_to new_user_session_path
    end

    context 'with valid user' do
      setup do
        create_common_test_objects
        sign_in default_user
      end

      should 'render the homepage' do
        get :index
        assert_response :success
      end

      should 'render the users_by_production_centre page' do
        get :users_by_production_centre
        assert_response :success
      end

      should 'render the consortia page' do
        get :consortia
        assert_response :success
      end
    end

  end
end
