# encoding: utf-8

require 'test_helper'

class CreateMiAttemptsInFormTest < ActionDispatch::IntegrationTest
  context 'When creating MI Attempt in form' do

    def choose_es_cell_from_list
      marker_symbol = 'Cbx1'
      es_cell_name = 'EPD0027_2_A01'
      fill_in 'marker_symbol-search-box', :with => marker_symbol
      click_button 'Search'
      sleep 5
      find(:xpath, '//em[text()="' + es_cell_name + '"]').click
    end

    setup do
      Factory.create(:mi_attempt, :colony_name => 'MABC')
      login default_user.email
      click_link 'Create'
    end

    should 'save MI and redirect back to show page when valid data' do
      choose_es_cell_from_list
      fill_in 'mi_attempt[colony_name]', :with => 'MZSQ'
      select 'MGP', :from => 'mi_attempt[consortium_name]'
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
