require 'test_helper'

class SearchForEmiAttemptsByCloneNameTest < ActionDispatch::IntegrationTest
  context 'searching for emi attempts by clone name' do
    should 'work with a single clone name' do
      visit '/'
      fill_in 'clone_names', :with => 'EPD0127_4_E01'
      click_button 'Search'
      assert_match %r{http://www\.example\.com/emi_clones\?clone_names=EPD0127_4_E01$}, current_url

      assert page.has_css? 'tr:nth-child(2) td', :text => 'EPD0127_4_E01'
      assert page.has_css? 'tr:nth-child(2) td', :text => 'Trafd1'
      assert page.has_css? 'tr:nth-child(2) td', :text => 'Trafd1<sup>tm1a(EUCOMM)Wtsi</sup>'
      assert page.has_css? 'tr:nth-child(2) td', :text => '29 July 2008'
      assert page.has_css? 'tr:nth-child(2) td', :text => '30 July 2008'
      assert page.has_css? 'tr:nth-child(2) td', :text => 'MBSS'
    end
  end
end
