require 'test_helper'

class UserIntegrationTest < ActionDispatch::IntegrationTest
  context 'When managing user sessions' do

    context 'Login page' do
      should 'work with valid user' do
        Factory.create :user, :email => 'test@example.com'
        sleep 10
        login 'test@example.com'
        assert_match %r{^http://[^/]+/$}, current_url
        assert page.has_content? 'Logged in successfully'
      end

      should 'have remember_me checked by default' do
        visit '/users/login'
        assert page.has_css?('input#user_remember_me[@checked=checked]')
      end

      should 'display error when invalid username/password entered' do
        visit '/users/login'
        fill_in 'Email', :with => 'invaliduser@example.com'
        fill_in 'Password', :with => 'invalidpassword'
        click_button 'Login'

        assert_match %r{^http://[^/]+/users/login$}, current_url
        assert page.has_content? 'nvalid email or password'
      end
    end

    context 'Logout' do
      should 'work' do
        login
        click_link 'Logout'
        assert_match(%r{^http://[^/]+/users/login$}, current_url)
      end

      should 'disable logout link' do
        visit '/users/logout'
        assert page.has_no_css? 'a', :text => 'Logout'
      end
    end

  end
end
