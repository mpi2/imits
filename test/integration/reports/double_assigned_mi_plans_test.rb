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

      should 'allow users to visit the double-assignment page & see entries' do

        gene_cbx1 = Factory.create :gene_cbx1

        Factory.create :mi_plan, :gene => gene_cbx1,
          :consortium => Consortium.find_by_name('BaSH'),
          :production_centre => Centre.find_by_name('WTSI'),
          :mi_plan_status => MiPlanStatus['Assigned']

        Factory.create :mi_plan, :gene => gene_cbx1,
          :consortium => Consortium.find_by_name('JAX'),
          :production_centre => Centre.find_by_name('JAX'),
          :number_of_es_cells_starting_qc => 5
          
        sleep 4

        visit '/reports/double_assigned_plans'
        assert_match '/reports/double_assigned_plans', current_url

        assert page.has_css?('div#double-matrix tr:nth-child(2) td:nth-child(4)', :text => '1')
        assert page.has_css?('a', :text => 'Download Matrix as CSV')

        assert_match 'Double-Assignments for Consortium: BaSH', page.body
        assert_match 'Double-Assignments for Consortium: JAX', page.body

        assert page.has_content? "Marker Symbol Consortium Plan Status MI Status Centre MI Date"
        assert page.has_content? "Cbx1 BaSH Assigned"

        assert page.has_css?('a', :text => 'Download List as CSV')
  
        tr_count = 3

        assert page.has_css?("div#double-list tr:nth-child(#{tr_count}) td:nth-child(1)", :text => 'Cbx1')        
        assert page.has_css?("div#double-list tr:nth-child(#{tr_count}) td:nth-child(2)", :text => /JAX/)
        assert page.has_css?("div#double-list tr:nth-child(#{tr_count}) td:nth-child(3)", :text => /Assigned - ES Cell QC In Progress/)
        assert page.has_css?("div#double-list tr:nth-child(#{tr_count}) td:nth-child(4)", :text => '')
        assert page.has_css?("div#double-list tr:nth-child(#{tr_count}) td:nth-child(5)", :text => /JAX/)
        assert page.has_css?("div#double-list tr:nth-child(#{tr_count}) td:nth-child(6)", :text => '')
        
        tr_count = 2

        assert page.has_css?("div#double-list tr:nth-child(#{tr_count}) td:nth-child(1)", :text => 'Cbx1')        
        assert page.has_css?("div#double-list tr:nth-child(#{tr_count}) td:nth-child(2)", :text => /BaSH/)
        assert page.has_css?("div#double-list tr:nth-child(#{tr_count}) td:nth-child(3)", :text => /Assigned/)
        assert page.has_css?("div#double-list tr:nth-child(#{tr_count}) td:nth-child(4)", :text => '')
        assert page.has_css?("div#double-list tr:nth-child(#{tr_count}) td:nth-child(5)", :text => /WTSI/)
        assert page.has_css?("div#double-list tr:nth-child(#{tr_count}) td:nth-child(6)", :text => '')

      end

    end

  end
end
