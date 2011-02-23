require 'test_helper'

class EditMiAttemptsTest < ActionDispatch::IntegrationTest
  context 'MI attempt editing' do
    should 'allow choice between all centres in the system' do
      visit '/emi_attempts?clone_names=EPD0127_4_E01'
      assert page.has_css? '.x-grid3-cell-inner'
    end
  end
end
