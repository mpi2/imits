require 'test_helper'

class ReportsTest < ActionDispatch::IntegrationTest
  context 'The reports pages' do
    should 'require the user to be logged in' do
      visit '/reports'
      assert_login_page
    end

    context 'once logged in' do
      setup do
        create_common_test_objects
        visit '/users/logout'
        login
      end

      should 'allow users to visit the reports "home" page' do
        visit '/reports'
        assert_match reports_path, current_url
      end

      should 'allow users to get reports of all MIs in the system' do
        visit '/reports'
        click_link 'All Micro-injections'

        assert_match '/reports/microinjection_list', current_url
        assert page.has_css?('form')
        assert page.has_css?('form select#grouping')

        select 'WTSI', :from => 'production_centre_id[]'
        click_button 'Generate Report'

        assert_match '/reports/microinjection_list', current_url
        assert_match 'production_centre_id', current_url
        assert page.has_css?('.report table')

        choose 'format_csv'
        click_button 'Generate Report'
      end

      should 'allow users to get production summary reports' do
        visit '/reports'
        click_link 'Month-by-Month Production Summary'

        assert_match '/reports/production_summary', current_url
        assert page.has_css?('form')
        assert_false page.has_css?('form select#grouping')

        select 'WTSI', :from => 'production_centre_id[]'
        click_button 'Generate Report'

        assert_match '/reports/production_summary', current_url
        assert_match 'production_centre_id', current_url
        assert page.has_css?('.report table')

        choose 'format_csv'
        click_button 'Generate Report'
      end

      should 'allow users to get gene summary reports' do
        visit '/reports'
        click_link 'Gene Summary'

        assert_match '/reports/gene_summary', current_url
        assert page.has_css?('form')
        assert_false page.has_css?('form select#grouping')

        select 'WTSI', :from => 'production_centre_id[]'
        click_button 'Generate Report'

        assert_match '/reports/gene_summary', current_url
        assert_match 'production_centre_id', current_url
        assert page.has_css?('.report table')

        choose 'format_csv'
        click_button 'Generate Report'
      end

      should 'allow users to get planned_microinjections reports' do
        5.times { Factory.create :mi_plan }

        visit '/reports'
        click_link 'Planned Micro-injections and Conflicts'

        assert_match '/reports/planned_microinjections', current_url
        assert page.has_css?('.report table')

        click_link 'download this report as csv'
        assert_match '/reports/planned_microinjections', current_url
      end
    end
  end
end
