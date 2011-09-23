# encoding: utf-8

require 'test_helper'

class EditMiAttemptsInGridTest < ActionDispatch::IntegrationTest
  context 'Editing MI Attempt in grid' do

    setup do
      @user1 = Factory.create(:user, :email => 'user1@example.com')
      @user2 = Factory.create(:user, :email => 'user2@example.com')
      es_cell = Factory.create(:es_cell_EPD0343_1_H06)
      @default_mi_attempt = es_cell.mi_attempts.first
      @default_mi_attempt.updated_by = @user1
      @default_mi_attempt.save!
    end

    def assert_mi_attempt_was_edited
      login(@user2.email)
      visit '/mi_attempts?search_terms=EPD0343_1_H06'

      yield

      click_button 'Save Changes'

      sleep 6

      @default_mi_attempt.reload
      assert_in_delta Time.now, @default_mi_attempt.updated_at, 60.seconds
      assert_equal @user2.email, @default_mi_attempt.updated_by.email
    end

    should 'work for emma status changes' do
      assert_mi_attempt_was_edited do
        find('.x-grid3-col-emma_status').click # The cell containing EMMA status
        find('.x-editor .x-form-trigger').click # The combo box down arrow
        find('.x-combo-list-item:nth-child(4)').click # 'Unsuitable for EMMA - STICKY'
      end
      assert_equal 'unsuitable_sticky', @default_mi_attempt.emma_status
    end

    should 'work for simple numeric field changes' do
      assert_mi_attempt_was_edited do
        visit '/mi_attempts?search_terms=EPD0343_1_H06'
        find('.x-grid3-col-total_pups_born').click # The cell containing 'Total Pups Born'
        sleep 1
        find('.x-editor input.x-form-text[@type=text]').set('12')
        sleep 1
        find('.x-grid3-col-es_cell__name').click # Make text-box lose focus
      end
      assert_equal 12, @default_mi_attempt.total_pups_born
    end

    context 'mouse allele type' do
      should 'be settable to a valid type' do
        login
        visit '/mi_attempts?search_terms=EPD0343_1_H06'
        find('.x-grid3-col-mouse_allele_type').click
        find('.x-editor .x-form-trigger').click # The combo box down arrow
        find('.x-combo-list-item', :text => 'e - Targeted Non-Conditional').click

        click_button 'Save Changes'

        sleep 6

        @default_mi_attempt.reload
        assert_equal 'e', @default_mi_attempt.mouse_allele_type

        assert page.has_css?('.x-grid3-col-mouse_allele_symbol', :text => 'Myo1ctm1e(EUCOMM)Wtsi')
      end

      should 'be settable to nil' do
        login
        visit '/mi_attempts?search_terms=EPD0343_1_H06'
        find('.x-grid3-col-mouse_allele_type').click
        find('.x-editor .x-form-trigger').click # The combo box down arrow
        find('.x-combo-list-item', :text => '[none]').click

        click_button 'Save Changes'

        sleep 6

        @default_mi_attempt.reload
        assert_equal nil, @default_mi_attempt.mouse_allele_type

        assert page.has_css?('.x-grid3-col-mouse_allele_symbol', :text => '')
      end

      should 'not be settable if allele type is nil (i.e. it was a deletion)' do
        MiAttempt.destroy_all
        deletion_es_cell = Factory.build(:es_cell, :gene => Factory.create(:gene, :marker_symbol => 'Cbx1'), :name => 'EPD_CUSTOM_1')
        deletion_es_cell.allele_symbol_superscript = 'tm1(EUCOMM)Wtsi'
        deletion_es_cell.save!
        assert_nil deletion_es_cell.allele_type
        Factory.create(:mi_attempt, :es_cell => deletion_es_cell)

        login
        visit '/mi_attempts?search_terms=EPD_CUSTOM_1'
        find('.x-grid3-col-mouse_allele_type').click
        assert page.has_no_css?('.x-editor .x-form-trigger')
      end
    end

  end
end
