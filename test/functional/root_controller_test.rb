# encoding: utf-8

require 'test_helper'

class RootControllerTest < ActionController::TestCase
  context 'RootController' do

    should 'require authentication' do
      get :index
      assert_redirected_to new_user_session_path
    end

    context 'with valid user' do
      should 'redirect to mi_attempts#index with production centre set to default user\'s one' do
        sign_in default_user
        get :index
        assert_redirected_to mi_attempts_path('q[production_centre_name]' => default_user.production_centre.name)
      end
    end

  end
end
