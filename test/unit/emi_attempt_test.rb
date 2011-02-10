require 'test_helper'

class EmiAttemptTest < ActiveSupport::TestCase
  should 'use table "emi_attempt"' do
    assert_equal 'emi_attempt', EmiAttempt.table_name
  end

  should 'belong to emi_event' do
    assert_equal emi_event('EPD0127_4_E01'), emi_attempt('EPD0127_4_E01__1').emi_event
  end

  should 'belong to emi clone through emi event' do
    assert_equal emi_clone('EPD0127_4_E01'), emi_attempt('EPD0127_4_E01__1').emi_clone
  end

  should '::by_clone_name works' do
    results = EmiAttempt.by_clone_name('EPD0127_4_E01')
    assert_equal 3, results.size
    assert results.include? emi_attempt('EPD0127_4_E01__1')
    assert results.include? emi_attempt('EPD0127_4_E01__2')
    assert results.include? emi_attempt('EPD0127_4_E01__3')
  end

end
