# encoding: utf-8

require 'test_helper'

class CreateMiAttemptsInFormTest < TarMits::JsIntegrationTest

  should 'require user to be logged in' do
    visit new_mi_attempt_path
    assert_login_page
  end

  context 'When creating MI Attempt in form' do

    setup do
      Factory.create :mi_attempt2, :colony_name => 'MABC'

      login
      click_link 'Create MI Attempt'
    end

    should 'save MI and redirect back to show page when valid data' do

      es_cell = Factory.create(:es_cell, :allele => Factory.create(:allele, :gene => cbx1))

      consortium_name = 'MGP'

      mi_plan = Factory.create :mi_plan, :production_centre => Centre.find_by_name!('WTSI'),
              :consortium => Consortium.find_by_name!(consortium_name),
              :status => MiPlan::Status[:Assigned],
              :gene => cbx1

      choose_es_cell_from_list cbx1.marker_symbol, es_cell.name

      choose_date_from_datepicker_for_input('mi_attempt[mi_date]')
      fill_in 'mi_attempt[colony_name]', :with => 'MZSQ'

      find(:xpath, '//td/div[text()="' + consortium_name + '"]').click

      click_button 'mi_attempt_submit'

      assert page.has_no_css?('#mi_attempt_submit[disabled]')

      assert_match /\/mi_attempts\/\d+$/, current_url

      ApplicationModel.uncached do
        mi_attempt = MiAttempt.find_by_colony_name!('MZSQ')
        assert_equal mi_attempt.colony_name, page.find('input[name="mi_attempt[colony_name]"]').value
        assert page.has_content? mi_attempt.consortium.name
        assert_equal default_user.email, mi_attempt.updated_by.email
      end
    end

    should 're-render form defaults filled in and validation errors when invalid data' do
      allele = TargRep::Allele.first
      es_cell = TargRep::EsCell.first

      choose_es_cell_from_list allele.gene.marker_symbol, es_cell.name
      fill_in 'mi_attempt[colony_name]', :with => 'MABC'
      click_button 'mi_attempt_submit'

      assert page.has_no_css?('#mi_attempt_submit[disabled]')

      assert_equal es_cell.name, page.find(:css, 'input[name="mi_attempt[es_cell_name]"]').value
      assert page.has_css? '.message.alert'
      assert page.has_css? '.field_with_errors'
      assert page.has_css? '.error-message'
    end
  end
end
