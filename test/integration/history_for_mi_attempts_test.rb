# encoding: utf-8

require 'test_helper'

class HistoryForMiAttemptsTest < ActionDispatch::IntegrationTest
  context 'History page' do
    should 'work' do
      login default_user
      mi_attempt = Factory.create :mi_attempt
      visit history_mi_attempt_path(mi_attempt)
      assert_match /History of Changes/, page.find('h2').text
      assert page.has_css? 'div.report table'
    end
  end
end
