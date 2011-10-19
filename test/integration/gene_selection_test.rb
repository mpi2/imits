# encoding: utf-8

require 'test_helper'

class GeneSelectionTest < Kermits2::JsIntegrationTest
  context 'the gene_selection page' do
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

      should 'allow users to visit the gene_selection page' do
        visit '/mi_plans/gene_selection'
        assert_match /gene_selection/, current_url

        # check we have some data in the grid
        assert page.has_css?('.x-grid-row')
        assert_equal 3, all('.x-grid-row').size
      end

      should 'allow users to filter the list of genes by marker symbol' do
        visit '/mi_plans/gene_selection'

        fill_in 'q[marker_symbol_or_mgi_accession_id_ci_in]', :with => 'Myo1c'
        click_button 'Search'

        # check we have just 1 row in our table
        assert page.has_css?('.x-grid-row')
        assert_equal 1, all('.x-grid-row').size
        assert page.has_no_css?('.x-grid-cell-inner', :text => 'Cbx1')
      end

      should 'allow users to filter the list of genes by MIs for consortia' do
        visit '/mi_plans/gene_selection'

        select 'EUCOMM-EUMODIC', :from => 'q[mi_plans_consortium_id_in][]'
        click_button 'Search'

        assert page.has_css?('.x-grid-row')
        assert_equal 2, all('.x-grid-row').size
        assert page.has_no_css?('.x-grid-cell-inner', :text => 'MGP')

        select 'EUCOMM-EUMODIC', :from => 'q[mi_plans_consortium_id_in][]'
        select 'MGP', :from => 'q[mi_plans_consortium_id_in][]'
        click_button 'Search'

        assert page.has_css?('.x-grid-row')
        assert_equal 3, all('.x-grid-row').size
      end

      should 'allow users to filter the list of genes by MIs at production centres' do
        visit '/mi_plans/gene_selection'

        select 'ICS', :from => 'q[mi_plans_production_centre_id_in][]'
        click_button 'Search'

        assert page.has_css?('.x-grid-row')
        assert_equal 1, all('.x-grid-row').size
        assert page.has_no_css?('.x-grid-cell-inner', :text => 'WTSI')

        select 'ICS', :from => 'q[mi_plans_production_centre_id_in][]'
        select 'WTSI', :from => 'q[mi_plans_production_centre_id_in][]'
        click_button 'Search'

        assert page.has_css?('.x-grid-row')
        assert_equal 3, all('.x-grid-row').size
      end

      should 'allow users to enter interest records (mi_plans)' do
        visit '/mi_plans/gene_selection'

        fill_in find('#consortium_combobox input')[:id], :with => 'Helmholtz GMC'
        fill_in find('#production_centre_combobox input')[:id], :with => 'HMGU'
        fill_in find('#priority_combobox input')[:id], :with => 'High'
        find('.x-grid-row-checker:first').click
        find('#register_interest_button button').click

        sleep 3

        assert page.has_css?('a.delete-mi-plan', :text => '[Helmholtz GMC:HMGU:Interest]')
        assert_equal 1, all('a.delete-mi-plan').size

        mi_plans = MiPlan.where(
          :consortium_id => Consortium.find_by_name!('Helmholtz GMC').id,
          :production_centre_id => Centre.find_by_name!('HMGU').id,
          :mi_plan_status_id => MiPlanStatus['Interest'].id
        )
        assert_equal 1, mi_plans.count

        visit '/mi_plans/gene_selection'

        fill_in find('#consortium_combobox input')[:id], :with => 'BaSH'
        fill_in find('#production_centre_combobox input')[:id], :with => ''
        fill_in find('#priority_combobox input')[:id], :with => 'Low'
        find('.x-grid-row-checker:first').click
        find('#register_interest_button button').click

        sleep 5

        assert_equal 2, all('a.delete-mi-plan').size
        assert page.has_css?('a.delete-mi-plan', :text => '[BaSH:Interest]')

        mi_plans = MiPlan.where( :consortium_id => Consortium.find_by_name!('BaSH').id )
        assert_equal 1, mi_plans.count
      end

      should 'allow users to delete non-assigned mi_plans' do
        mi_plan = Factory.create :mi_plan,
          :gene => Gene.find_by_marker_symbol!('Myo1c'),
          :consortium => Consortium.find_by_name!('Helmholtz GMC'),
          :production_centre => Centre.find_by_name!('HMGU'),
          :mi_plan_status => MiPlanStatus['Interest']
        mi_plan_id = mi_plan.id

        visit '/mi_plans/gene_selection'

        sleep 3

        assert page.has_css?('a.delete-mi-plan', :text => '[Helmholtz GMC:HMGU:Interest]')
        assert_equal 1, all('a.delete-mi-plan').size

        find('a.delete-mi-plan').click

        assert page.driver.browser.switch_to.alert.text.include?('[Helmholtz GMC:HMGU:Interest]')

        page.driver.browser.switch_to.alert.accept

        sleep 3
        assert_nil MiPlan.find_by_id(mi_plan_id)
      end
    end
  end
end

