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
        visit '/users/logout'
        login
      end

      should 'allow users to visit the gene_selection page' do
        3.times { Factory.create :mi_plan }
        visit '/mi_plans/gene_selection'
        assert_match(/gene_selection/, current_url)

        wait_until_grid_loaded
        assert page.has_css?('.x-grid-row')
        assert_equal 3, all('.x-grid-row').size
      end

      should 'allow users to filter the list of genes by marker symbol' do
        create_common_test_objects
        visit '/mi_plans/gene_selection'

        fill_in 'q[marker_symbol_or_mgi_accession_id_ci_in]', :with => 'Myo1c'
        click_button 'Search'

        wait_until_grid_loaded
        assert_equal 1, all('.x-grid-row').size
        assert page.has_no_css?('.x-grid-cell-inner', :text => 'Cbx1')
      end

      should 'allow users to filter the list of genes by MIs for consortia' do
        create_common_test_objects
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
        create_common_test_objects
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

      should 'allow users to delete mi_plans' do
        Factory.create :mi_attempt, :es_cell => Factory.create(:es_cell, :gene => cbx1)

        mi_plan = Factory.create :mi_plan,
                :gene => cbx1,
                :consortium => Consortium.find_by_name!('BaSH'),
                :production_centre => Centre.find_by_name!('WTSI')
        assert_equal 'Inspect - MI Attempt', mi_plan.status.name

        mi_plan_id = mi_plan.id

        visit '/mi_plans/gene_selection'

        assert page.has_css?('a.mi-plan', :text => '[BaSH:WTSI:Inspect - MI Attempt]')
        assert_equal 1, all('a.mi-plan').size

        find('a.mi-plan').click
        find('#delete-button').click
        find('#delete-confirmation-button').click
        wait_until_no_mask

        assert_equal 0, all('a.mi-plan').size

        sleep 3
        assert_nil MiPlan.find_by_id(mi_plan_id)
      end

      should_eventually 'allow users to edit mi_plans' do
        Factory.create :mi_attempt, :es_cell => Factory.create(:es_cell, :gene => cbx1)

        mi_plan = Factory.create :mi_plan,
                :gene => cbx1,
                :consortium => Consortium.find_by_name!('BaSH'),
                :production_centre => Centre.find_by_name!('WTSI')
        assert_equal 'Inspect - MI Attempt', mi_plan.status.name

        visit '/mi_plans/gene_selection'

        assert page.has_css?('.x-grid-row')
        assert_equal 1, all('a.mi-plan').size

        find('a.mi-plan', :text => '[BaSH:WTSI:Inspect - MI Attempt]').click
        assert page.has_css?('.plan.editor')

        fill_in 'number_of_es_cells_starting_qc', :with => '5'

        find('#update-button').click
        assert page.has_css?('.x-message-box button')
        all('.x-message-box button').detect {|b| b.text == 'Yes'}.click

        find('a.mi-plan', :text => '[BaSH:WTSI]').click
        assert page.has_css?('.plan.editor')

        fill_in 'number_of_es_cells_starting_qc', :with => '10'

        find('#update-button').click

        assert page.has_no_css?('.x-mask', :visible => true)

        mi_plan.reload

        wait_until { 10 == mi_plan.number_of_es_cells_starting_qc }

        assert_equal 'Assigned - ES Cell QC In Progress', mi_plan.status.name
      end
    end # once logged in

  end
end
