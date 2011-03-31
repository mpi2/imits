# encoding: utf-8

require 'test_helper'

class EditMiAttemptsTest < ActionDispatch::IntegrationTest

  def default_mi_attempt
    @default_mi_attempt ||= emi_attempt('EPD0343_1_H06__1')
  end

  def assert_mi_attempt_was_audited
    assert_equal 'vvi', default_mi_attempt.edited_by

    login
    visit '/mi_attempts?search_terms=EPD0343_1_H06'
    click_button 'Search'

    yield

    click_button 'Save Changes'

    sleep 6

    default_mi_attempt.reload
    assert_in_delta Time.now, default_mi_attempt.edit_date, 60.seconds
    assert_equal 'zz99', default_mi_attempt.edited_by
  end

  should 'audit MiAttempt when emma status changes' do
    assert_mi_attempt_was_audited do
      find('.x-grid3-col-emma_status').click # The cell containing EMMA status
      find('.x-editor .x-form-trigger').click # The combo box down arrow
      find('.x-combo-list-item:nth-child(4)').click # 'Unsuitable for EMMA - STICKY'
    end
    assert_equal :unsuitable_sticky, default_mi_attempt.emma_status
  end

  should 'audit MiAttempt when simple numeric field changes' do
    assert_mi_attempt_was_audited do
      find('.x-grid3-col-number_born').click # The cell containing 'Total Pups Born'
      find('.x-editor input.x-form-text[@type=text]').set('12')
      click_button 'Save Changes' # Make text-box lose focus.. will not submit
    end
    assert_equal 12, default_mi_attempt.number_born
  end

  should 'audit EmiEvent when distribution center changes' do
    assert_equal 'vvi', default_mi_attempt.emi_event.edited_by

    login
    visit '/mi_attempts'
    fill_in 'search_terms', :with => 'EPD0343_1_H06'
    click_button 'Search'

    find('.x-grid3-col-distribution_centre_name').click # The cell containing Dist. Centre
    find('.x-editor .x-form-trigger').click # The combo box down arrow
    find('.x-combo-list-item:nth-child(2)').click # 'ICS'

    click_button 'Save Changes'

    sleep 6

    default_mi_attempt.reload
    assert_in_delta Time.now, default_mi_attempt.emi_event.edit_date, 60.seconds
    assert_equal 'zz99', default_mi_attempt.emi_event.edited_by
  end

end
