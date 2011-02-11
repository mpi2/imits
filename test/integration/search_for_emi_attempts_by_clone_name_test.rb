require 'test_helper'

class SearchForEmiAttemptsByCloneNameTest < ActionDispatch::IntegrationTest
  context 'searching for emi attempts by clone name' do
    should 'work with a single clone name' do
      visit '/'
      fill_in 'clone_names', :with => 'EPD0127_4_E01'
      click_button 'Search'
      assert_match 'http://www.example.com/emi_attempts?clone_names=EPD0127_4_E01', current_url

      assert page.has_css? 'tr:nth-child(2) td', :text => 'EPD0127_4_E01'
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
