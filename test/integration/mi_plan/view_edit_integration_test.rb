# encoding: utf-8

require 'test_helper'

class MiPlan::ViewEditIntegrationTest < TarMits::JsIntegrationTest
  context 'When user not logged in grid' do
    should 'not have edit link' do
      visit '/'
      click_link 'Plans'
      assert page.has_no_content?('Edit In Form')
    end

    should 'not load mi_plan editor' do
      allele = Factory.create :allele, :gene => cbx1
      Factory.create :mi_attempt2,
        :mi_plan => TestDummy.mi_plan('DTCC', 'UCD', :gene => cbx1, :force_assignment => true),
        :es_cell => Factory.create(:es_cell, :allele => allele)

      mi_plan = Factory.create :mi_plan,
              :gene => cbx1,
              :consortium => Consortium.find_by_name!('BaSH'),
              :production_centre => Centre.find_by_name!('WTSI')
      assert_equal 'Inspect - MI Attempt', mi_plan.status.name

      visit '/'
      click_link 'Plans'
      find('.x-grid-cell-inner', :text => 'BaSH').click
      assert page.has_no_content?('Change Gene Interest')
    end
  end
  context 'View & Edit MiPlans tests:' do

    should 'display MiPlan data' do
      plan = Factory.create :mi_plan,
              :production_centre => Centre.find_by_name!('WTSI'),
              :consortium => Consortium.find_by_name!('BaSH'),
              :priority => MiPlan::Priority.find_by_name!('Medium'),
              :force_assignment => true,
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

    should 'allow users to withdraw mi_plans' do
      allele = Factory.create :allele, :gene => cbx1
      Factory.create :mi_attempt2,
        :mi_plan => TestDummy.mi_plan('DTCC', 'UCD', :gene => cbx1, :force_assignment => true),
        :es_cell => Factory.create(:es_cell, :allele => allele)

      mi_plan = Factory.create :mi_plan,
              :gene => cbx1,
              :consortium => Consortium.find_by_name!('BaSH'),
              :production_centre => Centre.find_by_name!('WTSI')
      assert_equal 'Inspect - MI Attempt', mi_plan.status.name

      login default_user
      visit '/mi_plans'

      find('.x-grid-cell-inner', :text => 'BaSH').click
      find('#withdraw-button').click
      find('#withdraw-confirmation-button').click

      wait_until_no_mask
      assert_equal 'Withdrawn', mi_plan.reload.status.name
    end

    should 'allow users to inactivate mi_plans' do
      mi_plan = Factory.create :mi_plan,
              :gene => Factory.create(:gene_cbx1),
              :consortium => Consortium.find_by_name!('BaSH'),
              :production_centre => Centre.find_by_name!('WTSI'),
              :force_assignment => true

      login default_user
      visit '/mi_plans'

      find('.x-grid-cell').click
      find('#inactivate-button').click
      find('#inactivate-confirmation-button').click

      assert page.has_no_css?('.x-mask', :visible => true)
      assert_equal 'Inactive', mi_plan.reload.status.name
    end

    should 'have link to edit form' do
      mi_plan = ApplicationModel.uncached { Factory.create :mi_plan, :production_centre => Centre.find_by_name!('WTSI') }
      login default_user
      visit '/mi_plans'
      assert page.has_css?("a[href=\"#{mi_plan_path(mi_plan)}\"]")
    end

  end
end
