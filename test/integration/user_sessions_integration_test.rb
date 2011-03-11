require 'test_helper'

class UserSessionsIntegrationTest < ActionDispatch::IntegrationTest
  context 'Logging in' do
    should 'work with valid user' do
      visit '/login'
      fill_in 'Username', :with => 'zz99'
      fill_in 'Password', :with => 's3cr31-6a55w0rd'
      click_button 'Login'

      assert_match %r{^http://[^/]+/$}, current_url
      assert page.has_css?('p', :text => 'You are logged in as Test User')
    end

    should 'display error with invalid user' do
      visit '/login'
      fill_in 'Username', :with => 'invaliduser'
      fill_in 'Password', :with => 'invalidpassword'
      click_button 'Login'

      assert_match %r{^http://[^/]+/login$}, current_url
      assert page.has_css? '#flash-error', :text => /incorrect/i
    end

  end
end
