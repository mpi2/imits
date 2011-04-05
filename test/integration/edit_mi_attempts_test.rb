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
    visit '/mi_attempts?search_terms=EPD0343_1_H06'

    find('.x-grid3-col-distribution_centre_name').click # The cell containing Dist. Centre
    find('.x-editor .x-form-trigger').click # The combo box down arrow
    find('.x-combo-list-item', :text => 'ICS').click

    click_button 'Save Changes'

    sleep 6

    default_mi_attempt.reload
    assert_in_delta Time.now, default_mi_attempt.emi_event.edit_date, 60.seconds
    assert_equal 'zz99', default_mi_attempt.emi_event.edited_by
    assert_equal 'ICS', default_mi_attempt.distribution_centre_name
  end

  context 'editing blast strain' do
    setup do
      login
      visit '/mi_attempts?search_terms=EPD0343_1_H06'

      find('.x-grid3-col-blast_strain').click # The grid cell
      find('.x-editor .x-form-trigger').click # The combo box down arrow
      find('.x-combo-list-item', :text => 'B6JTyr<c-Brd>').click
    end

    should 'work' do
      click_button 'Save Changes'
      sleep 6

      assert_equal 'B6JTyr<c-Brd>', default_mi_attempt.blast_strain
    end

    should 'show it in the interface properly' do
      assert_equal 'B6JTyr<c-Brd>', find('.x-grid3-col-blast_strain').text
      assert_equal 'B6JTyr<c-Brd>', find('.x-form-text').value
    end
  end

  context 'editing test cross strain' do
    setup do
      login
      visit '/mi_attempts?search_terms=EPD0343_1_H06'

      find('.x-grid3-col-test_cross_strain').click # The grid cell
      find('.x-editor .x-form-trigger').click # The combo box down arrow
      find('.x-combo-list-item', :text => 'B6JTyr<c-Brd>').click
    end

    should 'work' do
      click_button 'Save Changes'
      sleep 6

      assert_equal 'B6JTyr<c-Brd>', default_mi_attempt.test_cross_strain
    end

    should 'show it in the interface properly' do
      assert_equal 'B6JTyr<c-Brd>', find('.x-grid3-col-test_cross_strain').text
      assert_equal 'B6JTyr<c-Brd>', find('.x-form-text').value
    end
  end

  context 'editing back cross strain' do
    setup do
      login
      visit '/mi_attempts?search_terms=EPD0343_1_H06'

      find('.x-grid3-col-back_cross_strain').click # The grid cell
      find('.x-editor .x-form-trigger').click # The combo box down arrow
      find('.x-combo-list-item', :text => 'B6JTyr<c-Brd>').click
    end

    should 'work' do
      click_button 'Save Changes'
      sleep 6

      assert_equal 'B6JTyr<c-Brd>', default_mi_attempt.back_cross_strain
    end

    should 'show it in the interface properly' do
      assert_equal 'B6JTyr<c-Brd>', find('.x-grid3-col-back_cross_strain').text
      assert_equal 'B6JTyr<c-Brd>', find('.x-form-text').value
    end
  end

end
