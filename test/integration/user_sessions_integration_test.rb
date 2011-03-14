require 'test_helper'

class UserSessionsIntegrationTest < ActionDispatch::IntegrationTest

  context 'Login page' do
    should 'work with valid user' do
      login
      assert_match %r{^http://[^/]+/$}, current_url
      assert page.has_css?('p', :text => 'You are logged in as Test User')
    end

    should 'display error when invalid username/password entered' do
      visit '/login'
      fill_in 'Username', :with => 'invaliduser'
      fill_in 'Password', :with => 'invalidpassword'
      click_button 'Login'

      assert_match %r{^http://[^/]+/login$}, current_url
      assert page.has_css? '.flash.error', :text => /incorrect/i
    end
  end

  context 'Logout' do
    should 'work' do
      login
      click_link 'Logout'
      assert_match(%r{^http://[^/]+/login$}, current_url)
      assert page.has_css? '.flash.notice', :text => /logged out/i
    end

    should 'disable logout link' do
      visit '/logout'
      assert page.has_no_css? 'a', :text => 'Logout'
    end
  end
end
