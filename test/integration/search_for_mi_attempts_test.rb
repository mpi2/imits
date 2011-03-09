require 'test_helper'

class SearchForMiAttemptsTest < ActionDispatch::IntegrationTest

  def selector_for_table_cell(table_row)
    ".x-grid3-body .x-grid3-row:nth-child(#{table_row}) .x-grid3-cell-inner"
  end

  context 'searching for mi attempts by clone name' do
    context 'with a single clone' do
      setup do
        visit '/'
        assert_false page.has_css? 'x-grid3'
        fill_in 'search_terms', :with => 'EPD0343_1_H06'
        click_button 'Search'
        assert_match %r{^http://[^/]+/mi_attempts\?search_terms=EPD0343_1_H06$}, current_url
      end

      should 'show all data for that clone' do
        [
          'EPD0343_1_H06',
          'Myo1c',
          'Myo1ctm1a(EUCOMM)Wtsi',
          '13-Sep-2010',
          'MDCF',
          'WTSI',
          'Unsuitable for EMMA',
          'Micro-injected',
        ].each do |text|
          assert(page.has_css?(selector_for_table_cell(1), :text => text),
            "Expected text '#{text}' in table cell 1, but did not find it")
        end
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
      visit '/mi_attempts?search_terms=EPD0127_4_E01'

      assert page.has_css? '.x-grid3-cell-inner', :text => 'Suitable for EMMA'
      assert page.has_css? '.x-grid3-cell-inner', :text => 'Unsuitable for EMMA'
    end

    should 'show search terms when results are shown' do
      visit '/mi_attempts?search_terms=EPD0127_4_E01%0D%0AEPD0343_1_H06'
      assert page.has_css? '#search_terms', :text => "EPD0127_4_E01 EPD0343_1_H06"
    end
  end

  context 'searching for mi attempts by gene symbol' do
    setup do
      visit '/'
      assert_false page.has_css? 'x-grid3'
      fill_in 'search_terms', :with => 'Trafd1'
      click_button 'Search'
    end

    should 'work' do
      assert_match %r{^http://[^/]+/mi_attempts\?search_terms=Trafd1$}, current_url
      assert page.has_css? selector_for_table_cell(1), :text => 'EPD0127_4_E01'
    end

    should 'not find unmatched clones' do
      assert page.has_no_css?('.x-grid3-cell-inner', :text => 'EPD0343_1_H06')
    end
  end

  should 'work for search with no terms' do
    visit '/'
    click_button 'Search'
    assert page.has_no_css? 'error'
  end

  should 'clear form when Clear button is pushed' do
    visit '/'
    fill_in 'search_terms', :with => 'some text'
    click_button 'Clear'
    assert_blank find('#search_terms').text
  end

  should 'display test data warning' do
    visit '/'
    assert page.has_content? 'SAMPLE DATA'
  end
end
