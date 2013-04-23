# encoding: utf-8

require 'test_helper'

class NavigationTest < TarMits::IntegrationTest
  context 'Navigation' do
    context 'when not logged in' do
      setup { visit '/' }

      should 'show read only navigation' do
        visit '/'
        assert page.has_css? '#navigation'
        assert page.has_link?('Home', {:href => root_path})
        assert page.has_link?('Gene Selection', {:href => gene_selection_open_mi_plans_path})
        assert page.has_link?('Plans', {:href => open_mi_plans_path})
        assert page.has_no_link?('Create MI Attempt')
        assert page.has_link?('Mouse Production', {:href => open_mi_attempts_path})
        assert page.has_link?('Phenotyping', {:href => open_phenotype_attempts_path})
        assert page.has_no_link?('Reports')
        assert page.has_no_link?('Manual')
      end

      should 'select Mouse Production tab when on Mouse Production page selected regardless of actual URL' do
        click_link 'Mouse Production'
        assert_current_link 'Mouse Production'
        fill_in 'q[terms]', :with => 'cbx1'
        select 'WTSI', :from => 'q[production_centre_name]'
        assert_current_link 'Mouse Production'
      end

    end

    context 'when logged in' do
      setup { login }

      should 'show editable links in the navigation when not logged in' do
        visit '/'
        assert page.has_css? '#navigation'
        assert page.has_link?('Home', {:href => root_path})
        assert page.has_link?('Gene Selection', {:href => gene_selection_mi_plans_path})
        assert page.has_link?('Plans', {:href => mi_plans_path})
        assert page.has_link?('Create MI Attempt', {:href => new_mi_attempt_path})
        assert page.has_link?('Mouse Production', {:href => mi_attempts_path('q[production_centre_name]' => @default_user.production_centre.name)})
        assert page.has_link?('Phenotyping', {:href => phenotype_attempts_path('q[production_centre_name]' => @default_user.production_centre.name)})
        assert page.has_link?('Reports', {:href => reports_path})
        assert page.has_link?('Manual')
      end

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
