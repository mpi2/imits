require 'test_helper'

class SearchForEmiAttemptsByCloneNameTest < ActionDispatch::IntegrationTest

  def selector_for_table_cell(table_row)
    ".x-grid3-body .x-grid3-row:nth-child(#{table_row}) .x-grid3-cell-inner"
  end

  context 'searching for emi attempts by clone name' do
    context 'with a single clone' do
      setup do
        visit '/'
        assert_false page.has_css? 'x-grid3'
        fill_in 'search_terms', :with => 'EPD0343_1_H06'
        click_button 'Search'
        assert_match %r{^http://[^/]+/emi_attempts\?search_terms=EPD0343_1_H06$}, current_url
      end

      should 'show all data for that clone' do
        assert page.has_css? selector_for_table_cell(1), :text => 'EPD0343_1_H06'
        assert page.has_css? selector_for_table_cell(1), :text => 'Myo1c'
        assert page.has_css? selector_for_table_cell(1), :text => 'Myo1ctm1a(EUCOMM)Wtsi'
        assert page.has_css? selector_for_table_cell(1), :text => '13-Sep-2010'
        assert page.has_css? selector_for_table_cell(1), :text => 'MDCF'
        assert page.has_css? selector_for_table_cell(1), :text => 'WTSI'
        assert page.has_css? selector_for_table_cell(1), :text => 'off'
      end

      should 'not show data for other clones' do
        assert page.has_no_css?('.x-grid3-cell-inner', :text => 'EPD0127_4_E01')
      end
    end

    should 'work with a multiple clone names' do
      visit '/'
      fill_in 'search_terms', :with => "EPD0127_4_E01\nEPD0343_1_H06"
      click_button 'Search'

      assert page.has_css? '.x-grid3-cell-inner', :text => 'EPD0127_4_E01'
      assert page.has_css? '.x-grid3-cell-inner', :text => 'EPD0343_1_H06'
    end

    should 'work if whitespace around clone names' do
      visit '/'
      fill_in 'search_terms', :with => "  EPD0343_1_H06\t"
      click_button 'Search'

      assert page.has_css? selector_for_table_cell(1), :text => 'EPD0343_1_H06'
    end

    should 'show emma statuses' do
      visit '/emi_attempts?search_terms=EPD0127_4_E01'

      assert page.has_css? '.x-grid3-cell-inner', :text => 'on'
      assert page.has_css? '.x-grid3-cell-inner', :text => 'off'
    end
  end

end
