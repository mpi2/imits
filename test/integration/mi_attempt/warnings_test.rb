# encoding: utf-8

require 'test_helper'

class MiAttempt::WarningsTest < ActionDispatch::IntegrationTest
  context 'Warnings for mi_attempts:' do
    setup do
      login
    end

    should 'not show them when rendering mi_attempts/new' do
      visit new_mi_attempt_path
      choose_es_cell_from_list
      assert page.has_no_css?('#warnings')
    end

    should 'show them when there are warnings' do
      Factory.create :es_cell_EPD0127_4_E01

      visit new_mi_attempt_path
      choose_es_cell_from_list('Trafd1', 'EPD0127_4_E01')
      select 'BaSH', :from => 'mi_attempt[consortium_name]'
      click_button 'mi_attempt_submit'

      assert_match %r{/mi_attempts/new}, current_url

      within('#warnings') do
        assert page.has_css? 'li', :text => MiAttempt::WARNING_MESSAGES[:gene_already_micro_injected]
      end
    end

    should 'not show them on edit page'

  end
end
