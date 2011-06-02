# encoding: utf-8

require 'test_helper'

class EditMiAttemptsInFormTest < ActionDispatch::IntegrationTest
  context 'When editing MI Attempt in form' do

    should 'show default values' do
      create_common_test_objects
      mi_attempt = Clone.find_by_clone_name('EPD0343_1_H06').mi_attempts.first

      login
      visit edit_mi_attempt_path(mi_attempt)

      assert page.has_css? 'input[name="mi_attempt[colony_name]"]', :text => 'MDCF'
    end

  end
end
