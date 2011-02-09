require 'test_helper'

class EmiEventTest < ActiveSupport::TestCase
  should 'use table "emi_event"' do
    assert_equal 'emi_event', EmiEvent.table_name
  end

  should 'belong to emi_clone' do
    assert_equal emi_clone('EPD0127_4_E01'), emi_event('EPD0127_4_E01').emi_clone
  end

end
