# encoding: utf-8

require 'test_helper'

class User::AdminTest < TarMits::IntegrationTest

  context 'Admin integration:' do

    should 'require login' do
      visit '/user/admin'
      assert page.has_css? '.message.alert'
      assert_login_page
    end

    should 'not allow non-authorized users to access admin page' do
      login
      visit '/user/admin'
      assert_match root_url, current_url
      assert_match /unauthorized access detected/i, page.find('.message.alert').text
    end

    should 'allow authorized admins to become another user' do
      vvi = Factory.create :admin_user
      user = Factory.create :user
      login vvi
      assert page.has_content? "You are logged in as #{vvi.email}"

      visit '/user/admin'
      select user.email, :from => 'user_email'
      click_button 'Transform'

      assert_equal user_url, current_url
      assert page.has_content? "You are logged in as #{user.email}"
    end

    should 'let authorized admins to create users' do
      vvi = Factory.create :admin_user
      login vvi
      assert page.has_content? "You are logged in as #{vvi.email}"
      visit '/user/admin'
      fill_in 'user[email]', :with => 'newuser@example.com'
      select 'WTSI', :from => 'user[production_centre_id]'
      click_button 'Create User'

      user = User.find_by_email!('newuser@example.com')
      assert user.valid_password?('password')
      assert_equal 'WTSI', user.production_centre.name

      assert page.has_content? "You are logged in as newuser@example.com"
      assert_equal user_url, current_url
      assert_match 'created',  page.find('.message.notice').text
    end

    should 'validate when creating users' do
      vvi = Factory.create :admin_user
      login vvi
      assert page.has_content? "You are logged in as #{vvi.email}"
      visit '/user/admin'
      fill_in 'user[email]', :with => 'invalid email'
      click_button 'Create User'

      assert page.has_css?('legend', :text => 'Create New User')
      assert page.has_css?('.message.alert')
    end

  end
end
