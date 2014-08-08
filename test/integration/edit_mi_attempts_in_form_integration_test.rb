# encoding: utf-8

require 'test_helper'

class EditMiAttemptsInFormIntegrationTest < TarMits::JsIntegrationTest

  context 'When not logged in' do

    setup do
      create_common_test_objects
      es_cell = TargRep::EsCell.find_by_name('EPD0343_1_H06')
      @mi_attempt = Factory.create(:mi_attempt2,
        :es_cell => es_cell,
        :mi_plan => Factory.create(:mi_plan_with_production_centre, :gene => es_cell.gene, :force_assignment => true),
        :mi_date => '2011-06-09',
        :date_chimeras_mated => '2011-06-02',
        :colony_name => 'MAAB',
        :total_blasts_injected => 12,
        :test_cross_strain_name => '129P2'
      )
    end

    should 'not be able to edit MI Attempt' do
      visit mi_attempt_path(@mi_attempt)
      assert_login_page
    end
  end

  context 'When editing MI Attempt in form' do

    setup do
      create_common_test_objects
      es_cell = TargRep::EsCell.find_by_name('EPD0343_1_H06')
      @mi_attempt = Factory.create(:mi_attempt2,
        :es_cell => es_cell,
        :mi_plan => Factory.create(:mi_plan_with_production_centre, :gene => es_cell.gene, :force_assignment => true),
        :mi_date => '2011-06-09',
        :date_chimeras_mated => '2011-06-02',
        :colony_name => 'MAAB',
        :total_blasts_injected => 12,
        :test_cross_strain_name => '129P2'
      )
      login
      visit mi_attempt_path(@mi_attempt)
    end

    should 'show but not allow editing es_cell or gene' do
      assert_match /Myo1c/, page.find('.marker-symbol').text
      assert_match /EPD0343_1_H06/, page.find('.es-cell-name').text
    end

    should 'show default values' do
      assert_equal 'MGI:27:129P2', page.find('select[name="mi_attempt[test_cross_strain_name]"] option[selected=selected]').text
      assert_equal 'MAAB', page.find('input[name="mi_attempt[colony_name]"]').value
      assert_equal '09/06/2011', page.find('input[name="mi_attempt[mi_date]"]').value
      assert_equal '02/06/2011', page.find('input[name="mi_attempt[date_chimeras_mated]"]').value
      assert_equal '12', page.find('input[name="mi_attempt[total_blasts_injected]"]').value
    end

    should 'edit mi successfully, set updated_by and redirect back to show page' do
      fill_in 'mi_attempt[colony_name]', :with => 'ABCD'
      fill_in 'mi_attempt[total_blasts_injected]', :with => 22
      select 'MGI:18:C57BL/6N', :from => 'mi_attempt[test_cross_strain_name]'
      select 'pass', :from => 'qc_southern_blot'
      check 'mi_attempt[report_to_public]'

      assert_difference 'MiAttempt.count', 0 do
        click_button 'mi_attempt_submit'
        assert page.has_no_css?('#mi_attempt_submit[disabled]')
      end

      @mi_attempt.reload
      assert_equal 'ABCD', @mi_attempt.colony_name
      assert_equal 22, @mi_attempt.total_blasts_injected
      assert_equal 'C57BL/6N', @mi_attempt.test_cross_strain.name
      assert_equal 'pass', @mi_attempt.qc_southern_blot.description
      assert_equal true, @mi_attempt.report_to_public?
      assert_equal default_user.email, @mi_attempt.updated_by.email

      assert_match /\/mi_attempts\/#{@mi_attempt.id}$/, current_url
      assert_equal @mi_attempt.colony_name, page.find('input[name="mi_attempt[colony_name]"]').value
    end

    should 'handle validation errors' do
      assert MiAttempt.find_by_external_ref!('MBSS')
      fill_in 'mi_attempt[colony_name]', :with => 'MBSS'
      assert_difference 'MiAttempt.count', 0 do
        click_button 'mi_attempt_submit'
        assert page.has_no_css?('#mi_attempt_submit[disabled]')
      end
      assert_match /\/mi_attempts\/\d+$/, current_url
      assert page.has_css? '.message.alert'
    end

    should 'not let production centre or consortium be edited' do
      assert page.has_no_css?('select[name="mi_attempt[production_centre_name]"]')
      assert page.has_no_css?('select[name="mi_attempt[consortium_name]"]')
    end

  end
end
