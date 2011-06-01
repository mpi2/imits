# encoding: utf-8

require 'test_helper'

class NavigationTest < ActionDispatch::IntegrationTest
  context 'Navigation' do

    def assert_current_link(text)
      assert page.has_css? "#mainnav a.current:contains(\"#{text}\")"
    end

    should 'not be shown when not logged in' do
      visit '/'
      assert page.has_no_css? '#mainnav'
    end

    context 'when logged in' do
      setup { login }

      should 'select Search & Edit tab when on root page' do
        visit '/'
        assert_current_link 'Search & Edit'
      end

      should 'select Search & Edit tab when on Search & Edit page selected regardless of actual URL' do
        click_link 'Search & Edit'
        assert_current_link 'Search & Edit'
        fill_in 'search_terms', :with => 'cbx1'
        select 'WTSI', :from => 'production_centre_id'
        assert_current_link 'Search & Edit'
      end

      should 'select Create tab when on Create page' do
        click_link 'Create'
        assert_current_link 'Create'
      end

      should 'not select any tab when not on a tabbed page' do
        click_link 'Change password'
        assert page.has_no_css? '#mainnav a.current'
      end
    end

  end
end
