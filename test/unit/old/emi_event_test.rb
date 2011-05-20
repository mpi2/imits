# encoding: utf-8

require 'test_helper'

class Old::EmiEventTest < ActiveSupport::TestCase
  context 'Old::EmiEvent' do

    setup do
      @emi_event = Old::EmiEvent.find(6561)
    end

    should 'use table "emi_event"' do
      assert_equal 'emi_event', Old::EmiEvent.table_name
    end

    should 'be read only by default' do
      assert_equal true, @emi_event.readonly?
    end

    should 'belong to clone' do
      assert_equal Old::Clone.find(@emi_event.clone_id), @emi_event.clone
    end

    should 'belong to distribution_centre' do
      assert_equal Old::Centre.find_by_name('CNB'), @emi_event.distribution_centre
    end

    should 'have many emi attempts' do
      assert_kind_of Old::MiAttempt, @emi_event.mi_attempts.first
    end

  end
end
