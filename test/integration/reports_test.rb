require 'test_helper'

class ReportsTest < Kermits2::IntegrationTest
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
        click_link 'All Micro-Injection Attempts'

        assert_match '/reports/mi_attempts_list', current_url
        assert page.has_css?('form')
        assert page.has_css?('form select#grouping')

        select 'WTSI', :from => 'production_centre_id[]'
        click_button 'Generate Report'

        assert_match '/reports/mi_attempts_list', current_url
        assert_match 'production_centre_id', current_url
        assert page.has_css?('.report table')

        choose 'format_csv'
        click_button 'Generate Report'
      end

      should 'allow users to get production summary reports' do
        visit '/reports'
        click_link 'Month-by-Month Summary'

        assert_match '/reports/mi_attempts_monthly_production', current_url
        assert page.has_css?('form')
        assert_false page.has_css?('form select#grouping')

        select 'WTSI', :from => 'production_centre_id[]'
        click_button 'Generate Report'

        assert_match '/reports/mi_attempts_monthly_production', current_url
        assert_match 'production_centre_id', current_url
        assert page.has_css?('.report table')

        choose 'format_csv'
        click_button 'Generate Report'
      end

      should 'allow users to get gene summary reports' do
        visit '/reports'
        click_link 'Gene Summary'

        assert_match '/reports/mi_attempts_by_gene', current_url
        assert page.has_css?('form')
        assert_false page.has_css?('form select#grouping')

        select 'WTSI', :from => 'production_centre_id[]'
        click_button 'Generate Report'

        assert_match '/reports/mi_attempts_by_gene', current_url
        assert_match 'production_centre_id', current_url
        assert page.has_css?('.report table')

        choose 'format_csv'
        click_button 'Generate Report'
      end

      should 'confirm planned_microinjection_list include_plans_with_active_attempts defaults to yes' do
        visit '/reports/planned_microinjection_list'
        assert page.has_css?('select#include_plans_with_active_attempts option[value="true"][selected="selected"]')
      end

      should 'confirm planned_microinjection_summary_and_conflicts include_plans_with_active_attempts defaults to yes' do
        visit '/reports/planned_microinjection_summary_and_conflicts'
        assert page.has_css?('select#include_plans_with_active_attempts option[value="true"][selected="selected"]')
      end

      should 'allow users to get planned_microinjection_summary_and_conflicts reports' do
        15.times { Factory.create :mi_plan, :consortium_id => Consortium.find_by_name!('DTCC').id }
        20.times { Factory.create :mi_attempt }

        visit '/reports'
        click_link 'Plans and Conflicts for All Consortia'

        assert_match '/reports/planned_microinjection_summary_and_conflicts', current_url
        assert page.has_css?('form')
        assert_false page.has_css?('form select#grouping')

        click_button 'Generate Report'
        assert_match '/reports/planned_microinjection_summary_and_conflicts', current_url
        assert page.has_css?('.report table')

        select 'yes', :from => 'include_plans_with_active_attempts'
        click_button 'Generate Report'
        assert_match '/reports/planned_microinjection_summary_and_conflicts', current_url
        assert page.has_css?('.report table')

        choose 'format_csv'
        click_button 'Generate Report'
      end

      should 'allow users to get reports of all mi_plans in the system' do
        15.times { Factory.create :mi_plan, :consortium_id => Consortium.find_by_name!('DTCC').id }
        20.times { Factory.create :mi_attempt }

        visit '/reports'
        click_link 'All Planned Micro-Injections'

        assert_match '/reports/planned_microinjection_list', current_url
        assert page.has_css?('form')
        assert page.has_css?('form select#grouping')

        click_button 'Generate Report'
        assert_match '/reports/planned_microinjection_list', current_url
        assert page.has_css?('.report table')

        select 'yes', :from => 'include_plans_with_active_attempts'
        click_button 'Generate Report'
        assert_match '/reports/planned_microinjection_list', current_url
        assert page.has_css?('.report table')

        choose 'format_csv'
        click_button 'Generate Report'
      end

      should 'not blow up in the users face if they ask for silly data' do
        visit '/reports'
        click_link 'All Micro-Injection Attempts'

        select 'JAX', :from => 'production_centre_id[]'
        select 'MARC', :from => 'consortium_id[]'
        click_button 'Generate Report'

        assert_match '/reports/mi_attempts_list', current_url
        assert_match 'production_centre_id', current_url
        assert_match 'Sorry', page.body

        visit '/reports'
        click_link 'Month-by-Month Summary'

        select 'JAX', :from => 'production_centre_id[]'
        select 'MARC', :from => 'consortium_id[]'
        click_button 'Generate Report'

        assert_match '/reports/mi_attempts_monthly_production', current_url
        assert_match 'production_centre_id', current_url
        assert_match 'Sorry', page.body

        visit '/reports'
        click_link 'Gene Summary'

        select 'JAX', :from => 'production_centre_id[]'
        select 'MARC', :from => 'consortium_id[]'
        click_button 'Generate Report'

        assert_match '/reports/mi_attempts_by_gene', current_url
        assert_match 'production_centre_id', current_url
        assert_match 'Sorry', page.body

        15.times { Factory.create :mi_plan, :consortium_id => Consortium.find_by_name!('DTCC').id }
        20.times { Factory.create :mi_attempt }

        visit '/reports'
        click_link 'All Planned Micro-Injections'

        select 'JAX', :from => 'production_centre_id[]'
        select 'MARC', :from => 'consortium_id[]'
        click_button 'Generate Report'

        assert_match '/reports/planned_microinjection_list', current_url
        assert_match 'production_centre_id', current_url
        assert_match 'Sorry', page.body
      end

      context 'All Planned Micro-Injections' do
        should 'allow grouping by production centre' do
          Factory.create :mi_plan, :consortium => Consortium.find_by_name!('BaSH')
          Factory.create :mi_plan, :consortium => Consortium.find_by_name!('BaSH'),
                  :production_centre => Centre.find_by_name!('WTSI')

          visit '/reports/planned_microinjection_list'
          select 'BaSH', :from => 'consortium_id[]'
          select 'Production Centre', :from => 'grouping'
          click_button 'Generate Report'
          assert ! page.has_content?('Exception')
        end
      end

    end # once logged in

  end
end
