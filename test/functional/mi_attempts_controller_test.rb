require 'test_helper'

class MiAttemptsControllerTest < ActionController::TestCase
  context 'GET index' do
    should 'route from /' do
      assert_routing '/', { :controller => 'mi_attempts', :action => 'index' }
    end

    should 'be root path' do
      assert_equal '/', root_path
    end

    should 'redirect to login path if not logged in' do
      assert_nil @controller.__send__(:current_user)
      get 'index'
      assert_redirected_to page_url(login_path)
    end
  end
end
