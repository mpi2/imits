# encoding: utf-8

require 'test_helper'

class NavigationTest < Kermits2::IntegrationTest
  context 'Navigation' do

    should 'not be shown when not logged in' do
      visit '/'
      assert page.has_no_css? '#navigation'
    end

    context 'when logged in' do
      setup { login }

      should 'select Mouse Production tab when on Mouse Production page selected regardless of actual URL' do
        click_link 'Mouse Production'
        assert_current_link 'Mouse Production'
        fill_in 'q[terms]', :with => 'cbx1'
        select 'WTSI', :from => 'q[production_centre_name]'
        assert_current_link 'Mouse Production'
      end

      should 'select Create tab when on Create page' do
        click_link 'Create MI Attempt'
        assert_current_link 'Create MI Attempt'
      end

      should 'not select any tab when not on a tabbed page' do
        click_link 'Edit profile'
        assert page.has_no_css? '#navigation a.current'
      end
    end

  end
end
