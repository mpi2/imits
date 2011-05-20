require 'test_helper'

class Old::CloneTest < ActiveSupport::TestCase
  context 'Old::Clone' do
    should 'use table "emi_clone"' do
      assert_equal 'emi_clone', Old::Clone.table_name
    end

    should 'be read only by default' do
      record = Old::Clone.find(:first)
      assert_equal true, record.readonly?
    end

    should 'have many emi events' do
      assert_kind_of Old::EmiEvent, Old::Clone.find_by_clone_name('EPD0127_4_E01').emi_events.first
    end

    should 'have scope all_that_have_mi_attempts' do
      assert_equal 2705, Old::Clone.all_that_have_mi_attempts.all.size
    end
  end
end
