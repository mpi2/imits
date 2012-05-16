# encoding: utf-8

require 'test_helper'

class ViewEditIntegrationTest < Kermits2::JsIntegrationTest
  context 'View & Edit MiPlans in grid tests:' do

    should 'display MiPlan data' do
      plan = Factory.create :mi_plan,
              :production_centre => Centre.find_by_name!('WTSI'),
              :consortium => Consortium.find_by_name!('BaSH'),
              :priority => MiPlan::Priority.find_by_name!('Medium'),
              :status => MiPlan::Status['Assigned'],
              :gene => Factory.create(:gene_cbx1)
      user = Factory.create :user, :production_centre => plan.production_centre
      login user
      click_link 'Plans'
      [
        'WTSI',
        'BaSH',
        'Medium',
        'Assigned',
        'Cbx1'
      ].each do |text|
        assert(page.has_css?('div', :text => text),
          "Expected text '#{text}' in grid, but did not find it")
      end
    end

    should 'filter by user production centre by default' do
      plan = Factory.create :mi_plan,
              :production_centre => Centre.find_by_name!('WTSI'),
              :gene => Factory.create(:gene_cbx1)
      user = Factory.create :user, :production_centre => Centre.find_by_name!('ICS')
      login user
      visit '/mi_plans'
      assert(page.has_no_css?('div', :text => 'Cbx1'))
    end

    context 'sub-project editing' do
      should 'work for WTSI users' do
        user = Factory.create :user, :production_centre => Centre.find_by_name!('WTSI')
        plan = Factory.create :mi_plan, :production_centre => Centre.find_by_name!('WTSI')
        sleep 1
        login user
        visit '/mi_plans'
        assert page.has_no_css?('.plan.editor')
        page.find('div.x-grid-cell-inner').click
        assert page.has_css?('.plan.editor')
        assert page.find('.plan.editor div#sub_project_name').visible?
      end

      should 'not work for non-WTSI users' do
        user = Factory.create :user, :production_centre => Centre.find_by_name!('ICS')
        plan = Factory.create :mi_plan, :production_centre => Centre.find_by_name!('ICS')
        sleep 1
        login user
        visit '/mi_plans'
        assert page.has_no_css?('.plan.editor')
        page.find('div.x-grid-cell-inner').click
        assert page.has_css?('.plan.editor')
        sleep 1
        assert ! page.find('.plan.editor div#sub_project_name').visible?
      end
    end

    context 'bespoke allele editing' do
      should 'work for WTSI users' do
        user = Factory.create :user, :production_centre => Centre.find_by_name!('WTSI')
        plan = Factory.create :mi_plan,
              :production_centre => Centre.find_by_name!('WTSI'),
              :consortium => Consortium.find_by_name!('BaSH'),
              :priority => MiPlan::Priority.find_by_name!('Medium'),
              :status => MiPlan::Status['Assigned'],
              :gene => Factory.create(:gene_cbx1),
              :is_bespoke_allele => true
        sleep 1
        login user
        visit '/mi_plans'
        assert page.has_no_css?('.plan.editor')
        sleep 1
        page.find('div.x-grid-cell-inner').click
        assert page.has_css?('.plan.editor')
        assert page.find('.plan.editor div#is_bespoke_allele').visible?
      end

      should 'not work for non-WTSI users' do
        user = Factory.create :user, :production_centre => Centre.find_by_name!('ICS')
        plan = Factory.create :mi_plan,
              :production_centre => Centre.find_by_name!('ICS'),
              :consortium => Consortium.find_by_name!('DTCC'),
              :priority => MiPlan::Priority.find_by_name!('Medium'),
              :status => MiPlan::Status['Assigned'],
              :gene => Factory.create(:gene_cbx1),
              :is_bespoke_allele => true
        sleep 1
        login user
        visit '/mi_plans'
        assert page.has_no_css?('.plan.editor')
        sleep 1
        page.find('div.x-grid-cell-inner').click
        assert page.has_css?('.plan.editor')
        assert ! page.find('.plan.editor div#is_bespoke_allele').visible?
      end
    end

    should 'allow users to withdraw mi_plans' do
      mi_plan = Factory.create :mi_plan,
              :gene => Factory.create(:gene_cbx1),
              :consortium => Consortium.find_by_name!('BaSH'),
              :production_centre => Centre.find_by_name!('WTSI'),
              :status => MiPlan::Status['Conflict']

      login default_user
      visit '/mi_plans'

      find('.x-grid-cell').click
      find('#withdraw-button').click
      find('#withdraw-confirmation-button').click

      sleep 3
      assert_equal 'Withdrawn', mi_plan.reload.status.name
    end

    should 'allow users to inactivate mi_plans' do
      mi_plan = Factory.create :mi_plan,
              :gene => Factory.create(:gene_cbx1),
              :consortium => Consortium.find_by_name!('BaSH'),
              :production_centre => Centre.find_by_name!('WTSI'),
              :status => MiPlan::Status['Assigned']

      login default_user
      visit '/mi_plans'

      find('.x-grid-cell').click
      find('#inactivate-button').click
      find('#inactivate-confirmation-button').click

      sleep 300
      assert_equal 'Inactive', mi_plan.reload.status.name
    end

  end
end
