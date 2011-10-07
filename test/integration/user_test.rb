# encoding: utf-8

require 'test_helper'

class UserTest < ActionDispatch::IntegrationTest

  context 'User integration:' do

    setup do
      Capybara.current_driver = :rack_test
    end

    teardown do
      Capybara.use_default_driver
    end

    context 'changing passwords' do
      should 'require login' do
        visit '/users/edit'
        assert_login_page
      end

      should 'work' do
        user = Factory.create :user
        login(user.email)
        click_link 'Edit profile'
        fill_in 'user[current_password]', :with => 'password'
        fill_in 'user[password]', :with => 'new password'
        fill_in 'user[password_confirmation]', :with => 'new password'
        click_button 'user_submit'
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
        click_link 'Edit profile'
        fill_in 'user[current_password]', :with => 'password'
        fill_in 'user[password]', :with => 'new password'
        fill_in 'user[password_confirmation]', :with => 'wrong password confirmation'
        click_button 'user_submit'
        assert page.has_css? 'legend', :text => 'Change Password'
      end
    end

  end
end
