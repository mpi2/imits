# encoding: utf-8

require 'test_helper'

class EditMiAttemptsTest < ActionDispatch::IntegrationTest
  should 'audit MiAttempt on changes' do
    mi_attempt = emi_attempt('EPD0343_1_H06__1')
    assert_equal 'vvi', mi_attempt.edited_by

    login
    visit '/mi_attempts'
    fill_in 'search_terms', :with => 'EPD0343_1_H06'
    click_button 'Search'

    find('.x-grid3-col-emma-status').click # The cell containing EMMA status
    find('.x-editor .x-form-trigger').click # The combo box down arrow
    find('.x-combo-list-item:nth-child(4)').click # 'Unsuitable for EMMA - STICKY'

    click_button 'Save Changes'

    sleep 6

    mi_attempt.reload
    assert_in_delta Time.now, mi_attempt.edit_date, 60.seconds
    assert_equal 'zz99', mi_attempt.edited_by
  end

  should 'audit EmiEvent on changes' do
    mi_attempt = emi_attempt('EPD0343_1_H06__1')
    assert_equal 'vvi', mi_attempt.emi_event.edited_by

    login
    visit '/mi_attempts'
    fill_in 'search_terms', :with => 'EPD0343_1_H06'
    click_button 'Search'

    find('.x-grid3-col-distribution-centre-name').click # The cell containing Dist. Centre
    find('.x-editor .x-form-trigger').click # The combo box down arrow
    find('.x-combo-list-item:nth-child(2)').click # 'ICS'

    click_button 'Save Changes'

    sleep 6

    mi_attempt.reload
    assert_in_delta Time.now, mi_attempt.emi_event.edit_date, 60.seconds
    assert_equal 'zz99', mi_attempt.emi_event.edited_by
  end
end
