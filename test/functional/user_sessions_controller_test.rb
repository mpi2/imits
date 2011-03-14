require 'test_helper'

class UserSessionsControllerTest < ActionController::TestCase
  context 'GET new' do
    should 'route from /login' do
      assert_routing '/login', { :controller => 'user_sessions', :action => 'new' }
    end

    should 'be have login_path helper' do
      assert_equal '/login', login_path
    end
  end

  context 'POST create' do
    should 'set the current user with a correct username/password and redirect to /' do
      post :create, :username => 'zz99', :password => 'password'
      assert_redirected_to root_path
    end

    should 'redirect to /login with a flash error with an incorrect username/password' do
      post :create, :username => 'incorrect', :password => 'incorrect'
      assert_redirected_to login_path
      assert_not_nil flash[:error]
    end
  end

  context 'GET destroy' do
    setup do
      session[:current_username] = 'zz99'
      get :destroy
    end

    should 'logout user and redirect to /login with a message' do
      assert_redirected_to login_path
      assert_nil session[:current_username]
      assert_match /logged out/i, flash[:notice]
    end
  end
end
