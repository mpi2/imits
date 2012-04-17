# encoding: utf-8

require 'test_helper'

class RootControllerTest < Kermits2::IntegrationTest
  context 'the root controller' do
    should 'require the user to be logged in' do
      visit '/mi_plans/gene_selection'
      assert_login_page
    end

    context 'once logged in' do
      setup do
        create_common_test_objects
        visit '/users/logout'
        login
      end

      should 'go to the home page by default' do
        visit '/'
        assert page.has_css?('.homepage-links')
        assert page.body.include?('Welcome to iMits')
      end

      should 'allow users to see a list of other iMits users' do
        visit '/'
        click_link 'Users/Production Centres'

        assert_match /users_by_production_centre/, current_url
        assert page.body.include?('Users by Production Centre')
        assert page.body.include?('test@example.com')
      end

      should 'allow users to see a list of consortia using iMits' do
        visit '/'
        click_link 'Consortia'

        assert_match /consortia/, current_url
        assert page.body.include?('Consortia Using iMits')

        Consortium.all.each do |consortium|
          assert page.body.include?(consortium.name), "#{consortium.name} not found!"
        end
      end

      should 'render /debug_info page' do
        visit '/debug_info'
        assert page.has_css? '#content'
      end
    end
  end
end
