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

        assert_login_page
        assert page.has_content? 'nvalid email or password'
      end
    end

    context 'Logout' do
      should 'work' do
        login
        click_link 'Logout'
        assert_login_page
      end

      should 'disable logout link' do
        visit '/users/logout'
        assert page.has_no_css? 'a', :text => 'Logout'
      end
    end

    context 'changing passwords' do
      should 'require login' do
        visit '/users/edit'
        assert_login_page
      end

      should 'work' do
        user = Factory.create :user
        login(user.email)
        click_link 'Change password'
        fill_in 'Current password', :with => 'password'
        fill_in 'New password', :with => 'new password'
        fill_in 'Confirm new password', :with => 'new password'
        click_button 'Change password'
        assert_match %r{^http://[^/]+/$}, current_url

        visit '/users/logout'
        fill_in 'Email', :with => user.email
        fill_in 'Password', :with => 'new password'
        click_button 'Login'
        assert_match %r{^http://[^/]+/$}, current_url
      end

      should 'validate' do
        user = Factory.create :user
        login(user.email)
        click_link 'Change password'
        fill_in 'Current password', :with => 'password'
        fill_in 'New password', :with => 'new password'
        fill_in 'Confirm new password', :with => 'wrong password confirmation'
        click_button 'Change password'
        assert page.has_css? 'h1', :text => /Change Password/
      end
    end

  end
end
