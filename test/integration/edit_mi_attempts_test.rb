# encoding: utf-8

require 'test_helper'

class EditMiAttemptsTest < ActionDispatch::IntegrationTest
  context 'Editing an MI Attempt' do

    setup do
      clone = Factory.create(:clone_EPD0343_1_H06)
      @default_mi_attempt = clone.mi_attempts.first
    end

    def assert_mi_attempt_was_audited
      assert_equal 'vvi', @default_mi_attempt.edited_by

      login
      visit '/mi_attempts?search_terms=EPD0343_1_H06'

      yield

      click_button 'Save Changes'

      sleep 6

      @default_mi_attempt.reload
      assert_in_delta Time.now, @default_mi_attempt.edit_date, 60.seconds
      assert_equal 'zz99', @default_mi_attempt.edited_by
    end

    should 'audit MiAttempt when emma status changes' do
      visit '/mi_attempts?search_terms=EPD0343_1_H06'
      # assert_mi_attempt_was_audited do
        find('.x-grid3-col-emma_status').click # The cell containing EMMA status
        find('.x-editor .x-form-trigger').click # The combo box down arrow
        find('.x-combo-list-item:nth-child(4)').click # 'Unsuitable for EMMA - STICKY'
      # end
      click_button 'Save Changes'
      sleep 6
      @default_mi_attempt.reload
      assert_equal :unsuitable_sticky, @default_mi_attempt.emma_status
    end

    should 'audit MiAttempt when simple numeric field changes' do
      assert_mi_attempt_was_audited do
        find('.x-grid3-col-number_born').click # The cell containing 'Total Pups Born'
        sleep 1
        find('.x-editor input.x-form-text[@type=text]').set('12')
        sleep 1
        find('.x-grid3-col-clone_name').click # Make text-box lose focus
      end
      assert_equal 12, @default_mi_attempt.number_born
    end

    should 'audit EmiEvent when distribution center changes' do
      assert_equal 'vvi', @default_mi_attempt.emi_event.edited_by

      login
      visit '/mi_attempts?search_terms=EPD0343_1_H06'

      find('.x-grid3-col-distribution_centre_name').click # The cell containing Dist. Centre
      find('.x-editor .x-form-trigger').click # The combo box down arrow
      find('.x-combo-list-item', :text => 'ICS').click

      click_button 'Save Changes'

      sleep 6

      @default_mi_attempt.reload
      assert_in_delta Time.now, @default_mi_attempt.emi_event.edit_date, 60.seconds
      assert_equal 'zz99', @default_mi_attempt.emi_event.edited_by
      assert_equal 'ICS', @default_mi_attempt.distribution_centre_name
    end

    context 'mouse allele type' do
      should 'be settable to a valid type' do
        visit '/mi_attempts?search_terms=EPD0343_1_H06'
        find('.x-grid3-col-mouse_allele_type').click
        find('.x-editor .x-form-trigger').click # The combo box down arrow
        find('.x-combo-list-item', :text => 'e - Targeted Non-Conditional').click

        click_button 'Save Changes'

        sleep 6

        @default_mi_attempt.reload
        assert_equal 'e', @default_mi_attempt.mouse_allele_type

        assert page.has_css?('.x-grid3-col-mouse_allele_name', :text => 'Myo1c<sup>tm1e(EUCOMM)Wtsi</sup>')
      end

      should 'be settable to nil'

      should 'not be settable if allele type is nil (i.e. it was a deletion)'
    end

  end
end
