require 'test_helper'

class SearchForEmiAttemptsByCloneNameTest < ActionDispatch::IntegrationTest

  context 'searching for emi attempts by clone name' do
    should 'work with a single clone name' do
      visit '/'
      fill_in 'clone_names', :with => 'EPD0127_4_E01'
      click_button 'Search'
      sleep 3
      assert_match %r{^http://[^/]+/emi_attempts\?clone_names=EPD0127_4_E01$}, current_url

      #y find('.x-grid3-body .x-grid3-row:nth-child(1)').text
      assert page.has_css? '.x-grid3-body .x-grid3-row:nth-child(1) .x-grid3-cell-inner', :text => 'EPD0127_4_E01'
      assert page.has_css? 'tr:nth-child(2) td', :text => 'Trafd1'
      assert page.has_css? 'tr:nth-child(2) td', :text => 'Trafd1<sup>tm1a(EUCOMM)Wtsi</sup>'
      assert page.has_css? 'tr:nth-child(2) td', :text => '29 July 2008'
      assert page.has_css? 'tr:nth-child(2) td', :text => '30 July 2008'
      assert page.has_css? 'tr:nth-child(2) td', :text => 'MBSS'
    end

    should 'work with a multiple clone names' do
      visit '/'
      fill_in 'clone_names', :with => "EPD0127_4_E01\nEPD0343_1_H06"
      click_button 'Search'

      assert page.has_css? 'tr:nth-child(2) td', :text => 'EPD0127_4_E01'
      assert page.has_css? 'tr:nth-child(5) td', :text => 'EPD0343_1_H06'
    end

    should 'work if whitespace around clone names' do
      visit '/'
      fill_in 'clone_names', :with => "  EPD0127_4_E01\t"
      click_button 'Search'

      assert page.has_css? 'tr:nth-child(2) td', :text => 'EPD0127_4_E01'
    end
  end

end
