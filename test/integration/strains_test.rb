# encoding: utf-8

require 'test_helper'

class StrainsTest < ActionDispatch::IntegrationTest

  context 'editing blast strain' do
    setup do
      login
      visit '/mi_attempts?search_terms=EPD0343_1_H06'

      find('.x-grid3-col-blast_strain').click # The grid cell
      find('.x-editor .x-form-trigger').click # The combo box down arrow
      find('.x-combo-list-item', :text => 'C57BL/6J-Tyr<c-2J>').click
    end

    should 'work' do
      click_button 'Save Changes'
      sleep 6

      assert_equal 'C57BL/6J-Tyr<c-2J>', default_mi_attempt.blast_strain
    end

    should 'show it in the grid properly' do
      assert_equal 'C57BL/6J-Tyr<c-2J>', find('.x-grid3-col-blast_strain').text
    end

    should_eventually 'show it in the text area properly' do
      assert_equal 'C57BL/6J-Tyr<c-2J>', find('.x-form-text').value
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

    should 'show it in the grid properly' do
      assert_equal 'B6JTyr<c-Brd>', find('.x-grid3-col-test_cross_strain').text
    end

    should_eventually 'show it in the text area properly' do
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

    should 'show it in the grid properly' do
      assert_equal 'B6JTyr<c-Brd>', find('.x-grid3-col-back_cross_strain').text
    end

    should_eventually 'show it in the text area properly' do
      assert_equal 'B6JTyr<c-Brd>', find('.x-form-text').value
    end
  end

  should 'show display strains in grid cells that are not in the config files' do
    default_mi_attempt.blast_strain = 'NoStrain1'
    default_mi_attempt.back_cross_strain = 'NoStrain2'
    default_mi_attempt.test_cross_strain = 'NoStrain3'
    default_mi_attempt.save!

    login
    visit '/mi_attempts?search_terms=EPD0343_1_H06'
    assert page.has_css?(selector_for_table_cell(1), :text => 'NoStrain1')
    assert page.has_css?(selector_for_table_cell(1), :text => 'NoStrain2')
    assert page.has_css?(selector_for_table_cell(1), :text => 'NoStrain3')
  end

end
