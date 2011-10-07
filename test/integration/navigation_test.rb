# encoding: utf-8

require 'test_helper'

class NavigationTest < ActionDispatch::IntegrationTest
  context 'Navigation' do

    should 'not be shown when not logged in' do
      visit '/'
      assert page.has_no_css? '#navigation'
    end

    context 'when logged in' do
      setup { login }

      should 'filter by user\'s production centre when Search & Edit is clicked' do
        click_link 'Search & Edit MI Attempts'
        assert_equal default_user.production_centre.name,
                page.find('select[name="q[production_centre_name]"] option[selected=selected]').value
      end

      should 'select Search & Edit tab when on Search & Edit page selected regardless of actual URL' do
        click_link 'Search & Edit MI Attempts'
        assert_current_link 'Search & Edit MI Attempts'
        fill_in 'q[terms]', :with => 'cbx1'
        select 'WTSI', :from => 'q[production_centre_name]'
        assert_current_link 'Search & Edit MI Attempts'
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
