require 'test_helper'

class EmiEventTest < ActiveSupport::TestCase
  should 'use table "emi_event"' do
    assert_equal 'emi_event', EmiEvent.table_name
  end
end
