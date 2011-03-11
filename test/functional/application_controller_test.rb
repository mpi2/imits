require 'test_helper'

class ApplicationControllerTest < ActionController::TestCase

  context '#current_user' do
    should 'be nil initially' do
      assert_nil @controller.__send__(:current_user)
    end

    should 'be the user whose user_name is in session[:current_user_name]' do
      session[:current_username] = 'zz99'
      assert_equal per_person('zz99'), @controller.__send__(:current_user)
    end
  end

end
