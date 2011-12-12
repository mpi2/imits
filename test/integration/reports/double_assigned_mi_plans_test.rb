# encoding: utf-8

require 'test_helper'

class Reports::DoubleAssignedMiPlansTest < ActionDispatch::IntegrationTest

  context 'Double-Assigned MI Plans test:' do

    context 'once logged in' do
      setup do
        create_common_test_objects
        visit '/users/logout'
        login
      end

      should 'allow users to visit the double-assignment page & see entries' do

        gene_cbx1 = Factory.create :gene_cbx1

        Factory.create :mi_plan, :gene => gene_cbx1,
          :consortium => Consortium.find_by_name('BaSH'),
          :production_centre => Centre.find_by_name('WTSI'),
          :status => MiPlan::Status['Assigned']

        Factory.create :mi_plan, :gene => gene_cbx1,
          :consortium => Consortium.find_by_name('JAX'),
          :production_centre => Centre.find_by_name('JAX'),
          :number_of_es_cells_starting_qc => 5

        visit '/reports/double_assigned_plans'
        assert_match '/reports/double_assigned_plans', current_url

        assert page.has_css?('div#double-matrix tr:nth-child(2) td:nth-child(4)', :text => '1')
        assert page.has_css?('a', :text => 'Download Matrix as CSV')

        assert_match 'Double-Assignments for Consortium: BaSH', page.body
        assert_match 'Double-Assignments for Consortium: JAX', page.body

        assert page.has_content? "Marker Symbol Consortium Plan Status MI Status Centre MI Date"
        assert page.has_content? "Cbx1 BaSH Assigned"

        assert page.has_css?('a', :text => 'Download List as CSV')

        assert_equal 3, all('table').count

      end

    end

  end
end
