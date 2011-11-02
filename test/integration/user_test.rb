# encoding: utf-8

require 'test_helper'

class UserTest < ActionDispatch::IntegrationTest

  context 'User integration:' do

    context 'changing passwords' do
      should 'require login' do
        visit user_path
        assert_login_page
      end

      should 'work' do
        user = Factory.create :user
        login user
        click_link 'Edit profile'
        fill_in 'user[password]', :with => 'new password'
        fill_in 'user[password_confirmation]', :with => 'new password'
        click_button 'user_submit'
        assert_match %r{^http://[^/]+/user$}, current_url
        assert page.has_css? 'legend', :text => 'Change Password'

        visit '/users/logout'
        fill_in 'Email', :with => user.email
        fill_in 'Password', :with => 'new password'
        click_button 'Login'
        assert_current_link 'Home'
      end

      should 'validate' do
        user = Factory.create :user
        login user
        click_link 'Edit profile'
        assert page.has_no_css? '.message.alert'

        fill_in 'user[password]', :with => 'new password'
        click_button 'user_submit'
        assert page.has_css? '.message.alert'
        assert page.has_css? 'legend', :text => 'Change Password'
      end
    end

    should 'allow changing name' do
      user = Factory.create :user
      assert_blank user.name

      login user
      click_link 'Edit profile'
      fill_in 'user[name]', :with => 'New Name Of User'
      click_button 'user_submit'
      assert page.has_css? '.message.notice'
      assert page.has_css?('input[name="user[name]"]', :value => 'New Name Of User')
    end

    should 'allow contactable to be modified' do    
      user = Factory.create :user
      assert_false user.is_contactable?

      login user
      click_link 'Edit profile'
      check 'user[is_contactable]'
      click_button 'user_submit'

      user.reload
      
      assert_true user.is_contactable?
    end

  end
end
