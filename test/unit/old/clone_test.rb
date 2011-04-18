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
  end
end
