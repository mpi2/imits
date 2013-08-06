# encoding: utf-8

require 'test_helper'

class GeneSelectionTest < TarMits::JsIntegrationTest

  context 'When user is not logged in grid' do

    should 'not display tree' do
      visit '/'
      click_link 'Gene Summary'
      assert page.has_no_content?('Tree')
    end

    should 'not allow user to edit mi_plans' do

      Factory.create :mi_attempt2, :es_cell => Factory.create(:es_cell, :allele => Factory.create(:allele, :gene => cbx1)),
          :mi_plan => bash_wtsi_cbx1_plan

      mi_plan = Factory.create :mi_plan,
              :gene => cbx1,
              :consortium => Consortium.find_by_name!('MGP'),
              :production_centre => Centre.find_by_name!('WTSI')
      assert_equal 'Inspect - MI Attempt', mi_plan.status.name

      visit '/'
      click_link 'Gene Summary'
      assert page.has_css?('.x-grid-row')
      assert_equal 1, all('a.mi-plan').size
      find('a.mi-plan', :text => '[MGP:WTSI:Inspect - MI Attempt]').click

      assert page.has_no_css?('.plan.editor')
    end
  end

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
    end # once logged in

  end
end
