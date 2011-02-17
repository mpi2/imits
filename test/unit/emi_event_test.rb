require 'test_helper'

class EmiEventTest < ActiveSupport::TestCase

  def default_emi_event
    @emi_event ||= emi_event('EPD0127_4_E01')
  end

  should 'use table "emi_event"' do
    assert_equal 'emi_event', EmiEvent.table_name
  end

  should 'belong to emi_clone' do
    assert_equal emi_clone('EPD0127_4_E01'), default_emi_event.emi_clone
  end

  should 'belong to distribution_centre' do
    assert_equal per_centre('ICS'), default_emi_event.distribution_centre
  end

end
