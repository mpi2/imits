require 'test_helper'

class ReportsTest < TarMits::IntegrationTest
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

      should 'confirm planned_microinjection_summary_and_conflicts include_plans_with_active_attempts defaults to yes' do
        visit '/v2/reports/planned_microinjection_summary_and_conflicts'
      end

      should 'allow users to get planned_microinjection_summary_and_conflicts reports' do
        15.times { Factory.create :mi_plan, :consortium_id => Consortium.find_by_name!('DTCC').id }
        20.times { Factory.create :mi_attempt2 }

        visit '/reports'
        click_link 'Plans and Conflicts for All Consortia'

        assert_match '/v2/reports/planned_microinjection_summary_and_conflicts', current_url
      end

      should 'allow users to get reports of all mi_plans in the system' do
        15.times { Factory.create :mi_plan, :consortium_id => Consortium.find_by_name!('DTCC').id }
        20.times { Factory.create :mi_attempt2 }

        visit '/reports'
        click_link 'All Planned Micro-Injections'

        assert_match '/reports/planned_microinjection_list', current_url
        assert page.has_css?('form')

        click_button 'Generate Report'
        assert_match '/reports/planned_microinjection_list', current_url

        click_button 'Generate Report'
        assert_match '/reports/planned_microinjection_list', current_url

        choose 'format_csv'
        click_button 'Generate Report'
      end

      should 'not blow up in the users face if they ask for silly data' do

        visit '/reports'
        click_link 'All Planned Micro-Injections'

        select 'MARC', :from => 'consortium_id[]'
        click_button 'Generate Report'

        assert_match '/reports/planned_microinjection_list', current_url
        assert_match 'Sorry', page.body
      end

      context 'All Planned Micro-Injections' do

        should 'return valid results for BaSH' do
          bash_plan1 = Factory.create :mi_plan,
                            :consortium => Consortium.find_by_name!('BaSH'),
                            :status => MiPlan::Status['Assigned']
          Reports::MiProduction::Intermediate.new.cache

          assert_equal 'Assigned', bash_plan1.status.name
          report = Reports::MiProduction::PlannedMicroinjectionList.new 'BaSH'
          report.cache
          visit '/reports/planned_microinjection_list'
          select 'BaSH', :from => 'consortium_id[]'
          click_button 'Generate Report'

          assert ! page.has_content?('Exception')
          assert page.has_content?('1 planned micro-injections found for BaSH')

          headings = ['Consortium', 'SubProject', 'Bespoke', 'Production Centre','Marker Symbol','MGI Accession ID','Priority','Plan Status','Best Status','Reason for Inspect/Conflict','Non-Assigned Plans','Assigned Plans','Aborted MIs','MIs in Progress','GLT Mice']
          headings.each { |heading| assert page.has_content?(heading) }

          contents = ['BaSH','No','Auto-generated Symbol','High','Assigned']
          contents.each { |content| assert page.has_content?(content) }

        end

      end

    end # once logged in

  end
end
