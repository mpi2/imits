# encoding: utf-8

require 'test_helper'

class DoubleAssignedMiPlansTest < ActionDispatch::IntegrationTest

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

      should 'allow users to visit the double-assignment matrix page' do
        visit '/reports/double_assigned_plans_matrix'
        assert_match '/reports/double_assigned_plans_matrix', current_url
      end

      should 'allow users to visit the double-assignment list page' do
        visit '/reports/double_assigned_plans_list'
        assert_match '/reports/double_assigned_plans_list', current_url
      end

      should 'allow users to visit the double-assignment matrix page by clicking' do
        visit '/reports'
        click_link 'Double-Assigned MI Plans Matrix'
        assert_match '/reports/double_assigned_plans_matrix', current_url
      end

      should 'allow users to visit the double-assignment list page by clicking' do
        visit '/reports'
        click_link 'Double-Assigned MI Plans List'
        assert_match '/reports/double_assigned_plans_list', current_url
      end


      should 'allow users to visit the double-assignment list page & see entries' do

        gene_cbx1 = Factory.create :gene_cbx1

        Factory.create :mi_plan, :gene => gene_cbx1,
          :consortium => Consortium.find_by_name('BaSH'),
          :production_centre => Centre.find_by_name('WTSI'),
          :mi_plan_status => MiPlanStatus['Assigned']

        Factory.create :mi_plan, :gene => gene_cbx1,
          :consortium => Consortium.find_by_name('JAX'),
          :production_centre => Centre.find_by_name('JAX'),
          :number_of_es_cells_starting_qc => 5

        visit '/reports/double_assigned_plans_list'
        assert_match '/reports/double_assigned_plans_list', current_url

        assert_match 'Double-Assignments for Consortium: BaSH', page.body
        assert_match 'Double-Assignments for Consortium: JAX', page.body

        assert page.has_content? "Marker Symbol Consortium Plan Status MI Status Centre MI Date"
        assert page.has_content? "Cbx1 BaSH Assigned"

        assert page.has_content? 'Download as CSV'
        assert page.has_css?('a', :text => 'Download as CSV')

      end

      should 'allow users to visit the double-assignment matrix page & see entries' do

        gene_cbx1 = Factory.create :gene_cbx1

        Factory.create :mi_plan, :gene => gene_cbx1,
          :consortium => Consortium.find_by_name('BaSH'),
          :production_centre => Centre.find_by_name('WTSI'),
          :mi_plan_status => MiPlanStatus['Assigned']

        Factory.create :mi_plan, :gene => gene_cbx1,
          :consortium => Consortium.find_by_name('JAX'),
          :production_centre => Centre.find_by_name('JAX'),
          :number_of_es_cells_starting_qc => 5

        visit '/reports/double_assigned_plans_matrix'
        assert_match '/reports/double_assigned_plans_matrix', current_url

        columns = Reports::MiPlans::DoubleAssignment.get_matrix_columns
        assert columns && columns.size > 0, "Could not get columns"

        size = all('tr').size
        assert_equal 15, all('tr').size

        trs = all('tr')
        tds = trs[1].all('td')

        assert_equal "1", tds[3].text
        assert page.has_content? 'Download as CSV'
        assert page.has_css?('a', :text => 'Download as CSV')

      end

    end

  end
end
