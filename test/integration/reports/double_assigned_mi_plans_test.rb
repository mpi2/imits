# encoding: utf-8

require 'test_helper'

class Reports::DoubleAssignedMiPlansTest < Kermits2::IntegrationTest

  context 'Double-Assigned MI Plans test:' do

    context 'once logged in' do
      setup do
        create_common_test_objects
        visit '/users/logout'
        login
      end

      should 'allow users to visit the double-assignment page & see entries' do
        assert cbx1
        es_cell_cbx1 = Factory.create :es_cell, :gene => cbx1

        Factory.create :mi_attempt2, :es_cell => es_cell_cbx1,
                :mi_plan => TestDummy.mi_plan('BaSH', 'WTSI', :gene => cbx1)

        Factory.create :mi_attempt2, :es_cell => es_cell_cbx1,
                :mi_plan => TestDummy.mi_plan('JAX', 'JAX', :gene => cbx1, :force_assignment => true)

        visit '/reports/double_assigned_plans'
        assert_match '/reports/double_assigned_plans', current_url

        assert page.has_css?('div#double-matrix tr:nth-child(2) td:nth-child(4)', :text => '1')
        assert page.has_css?('a', :text => 'Download Matrix as CSV')

        assert_match 'Double - Production for Consortium: BaSH', page.body
        assert_match 'Double - Production for Consortium: JAX', page.body

        assert page.has_content? "Marker Symbol Consortium MI Status Centre MI Date"
        assert page.has_content? "Cbx1 BaSH Micro-injection in progress"

        assert page.has_css?('a', :text => 'Download List as CSV')

        assert_equal 3, all('table').count

      end

    end

  end
end
