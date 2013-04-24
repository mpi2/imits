# encoding: utf-8

require 'test_helper'

class RootControllerTest < ActionController::TestCase
  context 'RootController' do

    context 'with no log on' do
      should 'render the consortia page' do
        get :consortia
        assert_response :success
      end

      context 'render the homepage' do
        setup do
          get :index
        end
        should respond_with :success
        should render_template(partial= 'open/root/index')
      end
    end

    should 'require authentication' do
      get :users_by_production_centre
      assert_redirected_to new_user_session_path
    end

    context 'with valid user' do
      setup do
        create_common_test_objects
        sign_in default_user
      end

      context 'render the homepage' do
        setup do
          get :index
        end
        should respond_with :success
        should render_template(partial= 'root/index')
      end

      should 'render the users_by_production_centre page' do
        get :users_by_production_centre
        assert_response :success
      end
    end

  end
end
