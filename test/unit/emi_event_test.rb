# encoding: utf-8

require 'test_helper'

class EmiEventTest < ActiveSupport::TestCase

  def default_emi_event
    @emi_event ||= emi_event('EPD0127_4_E01')
  end

  should 'use table "emi_event"' do
    assert_equal 'emi_event', EmiEvent.table_name
  end

  should 'belong to clone' do
    assert_equal emi_clone('EPD0127_4_E01'), default_emi_event.clone
  end

  should 'belong to distribution_centre' do
    assert_equal per_centre('ICS'), default_emi_event.distribution_centre
  end

  context 'auditing' do
    setup do
      assert_equal Time.parse('2008-12-05 09:37:46 Z'), default_emi_event.edit_date, "Test cannot continue - edit_date must be before NOW to make sure it is set correctly on edit"
      assert_not_equal 'jb27', default_emi_event.edited_by
      default_emi_event.update_attributes!(:comments => 'Comment')
      default_emi_event.reload
    end

    should 'set edit_date to time of editing' do
      assert_in_delta Time.now, default_emi_event.edit_date, 60.seconds
    end

    should 'set edited_by to jb27' do
      assert_equal 'jb27', default_emi_event.edited_by
    end
  end

end
