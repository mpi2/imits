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
        fill_in 'clone_names', :with => 'EPD0127_4_E01'
        click_button 'Search'
        sleep 3
        assert_match %r{^http://[^/]+/emi_attempts\?clone_names=EPD0127_4_E01$}, current_url
      end

      should 'show all data for that clone' do
        assert page.has_css? selector_for_table_cell(1), :text => 'EPD0127_4_E01'
        assert page.has_css? selector_for_table_cell(1), :text => 'Trafd1'
        assert page.has_css? selector_for_table_cell(1), :text => 'Trafd1tm1a(EUCOMM)Wtsi'
        assert page.has_css? selector_for_table_cell(1), :text => '29 July 2008'
        assert page.has_css? selector_for_table_cell(1), :text => '30 July 2008'
        assert page.has_css? selector_for_table_cell(1), :text => 'MBSS'
        assert page.has_css? selector_for_table_cell(1), :text => 'ICS'
      end

      should 'not show data for other clones' do
        assert page.has_no_css?('.x-grid3-cell-inner', :text => 'EPD0343_1_H06')
      end
    end

    should 'work with a multiple clone names' do
      visit '/'
      fill_in 'clone_names', :with => "EPD0127_4_E01\nEPD0343_1_H06"
      click_button 'Search'
      sleep 3

      assert page.has_css? selector_for_table_cell(1), :text => 'EPD0127_4_E01'
      assert page.has_css? selector_for_table_cell(4), :text => 'EPD0343_1_H06'
    end

    should 'work if whitespace around clone names' do
      visit '/'
      fill_in 'clone_names', :with => "  EPD0127_4_E01\t"
      click_button 'Search'

      assert page.has_css? selector_for_table_cell(2), :text => 'EPD0127_4_E01'
    end
  end

end
