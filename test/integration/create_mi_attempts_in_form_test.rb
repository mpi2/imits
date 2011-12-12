# encoding: utf-8

require 'test_helper'

class CreateMiAttemptsInFormTest < Kermits2::JsIntegrationTest
  context 'When creating MI Attempt in form' do

    setup do
      Factory.create(:mi_attempt, :colony_name => 'MABC')
      login
      click_link 'Create MI Attempt'
    end

    should 'save MI and redirect back to show page when valid data' do
      mi_plan = Factory.create :mi_plan, :production_centre => Centre.find_by_name!('WTSI'),
              :consortium => Consortium.find_by_name!('MGP'),
              :status => MiPlan::Status[:Assigned],
              :gene => Factory.create(:gene_cbx1)

      choose_es_cell_from_list
      make_form_element_usable('mi_attempt[mi_date]')

      fill_in 'mi_attempt[colony_name]', :with => 'MZSQ'
      fill_in 'mi_attempt[mi_date]', :with => '07/10/2011'
      select 'MGP', :from => 'mi_attempt[consortium_name]'
      select 'WTSI', :from => 'mi_attempt[production_centre_name]'
      click_button 'mi_attempt_submit'

      sleep 3

      assert_match /\/mi_attempts\/\d+$/, current_url
      mi_attempt = MiAttempt.find_by_colony_name!('MZSQ')
      assert_equal mi_attempt.colony_name, page.find('input[name="mi_attempt[colony_name]"]').value
      assert page.has_content? mi_attempt.consortium_name
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

    should 'show base errors' do
      es_cell = Factory.create :es_cell_EPD0127_4_E01_without_mi_attempts
      mi_plan = Factory.create :mi_plan,
              :consortium => Consortium.find_by_name!('BaSH'),
              :production_centre => Centre.find_by_name!('WTSI'),
              :gene => es_cell.gene,
              :number_of_es_cells_passing_qc => 0
      assert_equal 'Aborted - ES Cell QC Failed', mi_plan.status

      sleep 1.5

      choose_es_cell_from_list es_cell.marker_symbol, es_cell.name
      make_form_element_usable('mi_attempt[mi_date]')
      fill_in 'mi_attempt[mi_date]', :with => '01/01/2011'
      select 'BaSH', :from => 'mi_attempt[consortium_name]'
      select 'WTSI', :from => 'mi_attempt[production_centre_name]'
      click_button 'mi_attempt_submit'

      assert page.has_css? '.alert.message', :text => /ES cells failed QC/
    end

  end
end
