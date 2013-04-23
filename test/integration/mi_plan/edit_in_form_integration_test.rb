# encoding: utf-8

require 'test_helper'

class MiPlan::EditInFormIntegrationTest < TarMits::IntegrationTest

  should 'require user to be logged in' do
      p = Factory.create :mi_plan
      visit mi_plan_path p
      assert_login_page
  end

  context 'Edit MiPlans in Form tests:' do

    should 'edit page should work' do
      login
      p = Factory.create :mi_plan
      visit mi_plan_path p
      assert_equal 'Edit Plan', page.find('h2').text
    end

    context 'sub_project_name viewing and editing' do
      should 'work for WTSI users'

      should 'not work for non-WTSI users'
    end

    context 'is_bespoke_allele viewing and editing' do
      should 'work for WTSI users'

      should 'not work for non-WTSI users'
    end

  end
end
