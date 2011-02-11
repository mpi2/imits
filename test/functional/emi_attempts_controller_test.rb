require 'test_helper'

class EmiClonesControllerTest < ActionController::TestCase
  context 'GET index' do
    should 'route from /' do
      assert_routing '/', { :controller => 'emi_clones', :action => 'index' }
    end

    should 'be root path' do
      assert_equal '/', root_path
    end
  end
end
