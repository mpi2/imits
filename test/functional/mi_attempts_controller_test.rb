require 'test_helper'

class MiAttemptsControllerTest < ActionController::TestCase
  context 'MiAttempt controller' do

    context 'GET index' do
      should 'route from /' do
        assert_routing '/', { :controller => 'mi_attempts', :action => 'index' }
      end

      should 'be root path' do
        assert_equal '/', root_path
      end
    end

    context 'GET show' do
      should 'get one mi attempt by ID'
    end

  end
end
