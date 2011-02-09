require 'test_helper'

class SearchForEmiAttemptsByCloneIdTest < ActionDispatch::IntegrationTest
  context 'searching for emi attemps by clone id' do
    should 'work for a single clone id' do
      visit '/'
      fill_in 'textarea', :with => 'blah'
    end
  end
end
