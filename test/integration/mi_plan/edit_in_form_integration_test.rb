# encoding: utf-8

require 'test_helper'

class MiPlan::EditInFormIntegrationTest < Kermits2::IntegrationTest
  context 'Edit MiPlans in Form tests:' do

    should 'edit page should work' do
      login
      p = Factory.create :mi_plan
      visit mi_plan_path p
      assert_equal 'Edit Plan', page.find('h2').text
    end

  end
end
