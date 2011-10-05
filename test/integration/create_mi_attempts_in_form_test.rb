# encoding: utf-8

require 'test_helper'

class CreateMiAttemptsInFormTest < ActionDispatch::IntegrationTest
  context 'When creating MI Attempt in form' do

    setup do
      Factory.create(:mi_attempt, :colony_name => 'MABC')
      login
      click_link 'Create MI Attempt'
    end

    should 'save MI and redirect back to show page when valid data' do
      mi_plan = Factory.create :mi_plan, :production_centre => Centre.find_by_name!('WTSI'),
              :consortium => Consortium.find_by_name!('MGP'),
              :mi_plan_status => MiPlanStatus[:Assigned],
              :gene => Factory.create(:gene_cbx1)

      choose_es_cell_from_list
      fill_in 'mi_attempt[colony_name]', :with => 'MZSQ'
      select 'MGP', :from => 'mi_attempt[consortium_name]'
      select 'WTSI', :from => 'mi_attempt[production_centre_name]'
      click_button 'mi_attempt_submit'

      sleep 3

      assert_match /\/mi_attempts\/\d+$/, current_url
      mi_attempt = MiAttempt.find_by_colony_name('MZSQ')
      assert_equal mi_attempt.colony_name, page.find('input[name="mi_attempt[colony_name]"]').value
      assert_equal mi_attempt.consortium_name, page.find('select[name="mi_attempt[consortium_name]"]').value
      assert_equal default_user.email, mi_attempt.updated_by.email
    end

    should 're-render form defaults filled in and validation errors when invalid data' do
      choose_es_cell_from_list
      fill_in 'mi_attempt[colony_name]', :with => 'MABC'
      click_button 'mi_attempt_submit'

      sleep 3

      assert_equal 'EPD0027_2_A01', page.find(:css, 'input[name="mi_attempt[es_cell_name]"]').value
      assert_equal '', page.find(:css, 'select[name="mi_attempt[consortium_name]"]').value
      assert page.has_css? '.message.alert'
      assert page.has_css? '.field_with_errors'
      assert page.has_css? '.error-message'
    end

  end
end
